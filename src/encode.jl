# Encoding to SAT clauses
# Linear encoding for now 

#= Translate totally symbolic form into a useful form 

e.g. the symbolic expression z == x + y 

should become some kind of Constraint(+, z, x, y) object, where z, x and y now refer to the DiscreteVariables, not the symbolic ones!
=#


include("discrete_variables.jl")
include("operations.jl")
include("sat_problem.jl")
include("model.jl")
include("symbolic_problem.jl")
include("solver.jl")

struct LinearEncoder end

struct BoundedIntegerCSP
    variables 
    constraints
    varmap   # maps symbolic variables to the corresponding DiscreteVariable
end

# varmap gives the translation from strictly symbolic objects to actual Julia objects

get_bounds(x::Interval) = ceil(Int, x.lo):floor(Int, x.hi)

function BoundedIntegerCSP(prob::ConstraintSatisfactionProblem)
    variables = []
    varmap = Dict()

    for var in prob.vars 
        variable = DiscreteVariable(var, get_bounds(prob.domains[var]))
        push!(variables, variable)
        push!(varmap, var => variable)
    end

    constraints = prob.constraints

    return BoundedIntegerCSP(variables, constraints, varmap)
end

domain(x::DiscreteVariable) = x.domain

"Generate clauses for expression z = op(x, y)
E.g. encode z = x + y as 

(x == i) && (y == j) => z == i + j

Call this x_i && y_j => z_{i+j}

"

function clauses(op, z, x, y)

    clauses = []

    for i in domain(x)
        for j in domain(y)

            k = op(i, j)

            if k ∈ domain(z)   # allowed values 
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]) ∨ z.varmap[k])
            else
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]))
            end
        end
    end

    return clauses
end


# clauses(varmap, constraint::Num) = encode(constraint)

function encode(varmap, constraint)
    constraint2 = value(constraint)


    args = arguments(constraint2)
    z = args[1]
    op = operation(args[2])
    x, y = arguments(args[2])

    @show op, z, x, y


    return clauses(op, varmap[z], varmap[x], varmap[y])

end

# encode(prob::ConstraintSatisfactionProblem) = encode(prob, LinearEncoder())

function encode(prob::BoundedIntegerCSP)
    all_variables = []
    all_clauses = []

    domains = Dict(v.name => v.domain for v in prob2.variables)

    for var in prob.variables 
        append!(all_variables, var.booleans)
        append!(all_clauses, clauses(var))
    end

    for constraint in prob.constraints 
        append!(all_clauses, encode(prob.varmap, value(constraint)))
    end

    @show all_variables 
    @show all_clauses 

    return SymbolicSATProblem(identity.(all_variables), identity.(all_clauses))
end


#### Example


vars = @variables x, y, z 

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z == x + y
    z ≤ 3
]

prob = ConstraintSatisfactionProblem(vars, constraints)
prob2 = BoundedIntegerCSP(prob)

domain(prob2.variables[3])

prob3 = encode(prob2)



prob2.varmap[z].booleans

solve(prob3)

solve(prob3)

m = Model(prob2.variables, prob2.constraints)
solve(m)



domains = Dict(v.name => v.domain for v in prob2.variables)
varmap = prob2.varmap

encode(varmap, prob2.constraints[1])

dump(varmap, maxdepth=1)



encode(prob2)


show(prob3.clauses)