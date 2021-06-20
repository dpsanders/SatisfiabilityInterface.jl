# Encoding to SAT clauses
# Linear encoding for now 

#= Translate totally symbolic form into a useful form 

e.g. the symbolic expression z == x + y 

should become some kind of Constraint(+, z, x, y) object, where z, x and y now refer to the DiscreteVariables, not the symbolic ones!
=#

#### Constraints / relations
#= Types of unary, binary and ternary constraint  we want to parse

## Unary -- constraints on the domain of a single variable
x   # for Boolean variables *only*, states that x is true 
¬x  # for Boolean variables *only*, states that x is false 

### Look binary but only involve one variable
x == 1   # must write as x ~ 1 ?
x <= 1

## Binary (two *variables*)
x == y 
x <= y 
x ≠ y 

### Look ternary:
x + y == 3 
x + y <= 3

## Ternary 
x + y == z 
x + y <= z 
z <= x + y 


If we introduce new variables for each sum of two other variables then these reduce significantly 
to a single ternary constraint like z == x + y 
and the rest binary 
But maybe that is overkill?

e.g. x + y <= z  becomes 

u = x + y   # this is now an actual sum of DiscreteVariables, creating a new Node type?
<=(u, z)    





=#

# struct LinearEncoder end



struct BoundedIntegerCSP
    variables 
    constraints
    varmap   # maps symbolic variables to the corresponding DiscreteVariable
end

# varmap gives the translation from strictly symbolic objects to actual Julia objects

# get_bounds(x::Interval) = ceil(Int, x.lo):floor(Int, x.hi)

BoundedIntegerCSP(variables, constraints) = BoundedIntegerCSP(ConstraintSatisfactionProblem(variables, constraints))

function BoundedIntegerCSP(prob::ConstraintSatisfactionProblem)
    variables = []
    varmap = Dict()

    for var in prob.vars 
        variable = DiscreteVariable(var, prob.domains[var])
        push!(variables, variable)
        push!(varmap, var => variable)
    end

    constraints = prob.constraints

    return BoundedIntegerCSP(variables, constraints, varmap)
end


"Generate clauses for expression z = op(x, y)
E.g. encode z = x + y as 

(x == i) && (y == j) => z == i + j

Call this x_i && y_j => z_{i+j}
"
function clauses(::typeof(==), z, op2, x, y)   # e.g. z = x + y

    clauses = []

    for i in domain(x)
        for j in domain(y)
            
            k = op2(i, j)

            if k ∈ domain(z)
                # if x and y take those values then z must take value k
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]) ∨ z.varmap[k])

            else  # combination not allowed
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]))
            end
        end
    end

    return clauses
end


"Encode e.g. z <= x + y by banning combinations that don't work"
function clauses(op1, z, op2, x, y)

    clauses = []

    for i in domain(x)
        for j in domain(y)
            for k in domain(z)

                # translation of symbolic constraint into values
                if !( op1(k, op2(i, j)) )  
                    # combination is not allowed

                    push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]) ∨ ¬(z.varmap[k]))
                end
            end
        end
    end

    return clauses
end

"Assumes that op is a relation like <= or !="
function clauses(rel, z, x)
    # @show rel, z, x
    clauses = []

    for i in domain(x)
        for j in domain(z)

            if !rel(i, j)
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(z.varmap[j])) 
            end
        end
    end

    return clauses
end


"Assumes constraint is a binary or ternary relation"
function encode(varmap, constraint)

    # @show varmap, constraint

    constraint2 = value(constraint)
    op1 = operation(constraint2)
    args1 = arguments(constraint2)
    
    @show op1, args1

    z = args1[1]
    rhs = args1[2] 

    @show rhs
    
    if istree(rhs) && !(operation(rhs) == getindex)
        # something like z <= x + y
        op2 = operation(rhs)

        args2 = arguments(rhs)
        x, y = args2

        @show op2, x, y
        return clauses(op1, varmap[z], op2, varmap[x], varmap[y])
    
    else      # something like z ≠ x
        x = rhs

        return clauses(op1, varmap[z], varmap[x])
    end



    # @show op, z, x, y


    

end

# encode(prob::ConstraintSatisfactionProblem) = encode(prob, LinearEncoder())

function encode(prob::BoundedIntegerCSP)
    all_variables = []
    all_clauses = []

    domains = Dict(v.name => v.domain for v in prob.variables)

    for var in prob.variables 
        append!(all_variables, var.booleans)
        append!(all_clauses, clauses(var))
    end

    # @show prob.constraints

    for constraint in prob.constraints 
        @show constraint
        append!(all_clauses, encode(prob.varmap, value(constraint)))
    end

    # @show all_variables 
    # @show all_clauses 

    return SymbolicSATProblem(identity.(all_variables), identity.(all_clauses))
end


function solve(prob::BoundedIntegerCSP)
    sat_problem = encode(prob)

    status, result_dict = solve(sat_problem)

    (status == :unsat) && return status, missing

    return status, Dict(v => decode(result_dict, v) for v in prob.variables)
end


