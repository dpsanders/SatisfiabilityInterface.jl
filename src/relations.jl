





struct BinaryRelation{O, S, T}
    x::S
    y::T 
end

BinaryRelation{O}(x::X, y::Y) where {O,X,Y} = BinaryRelation{O,X,Y}(x, y)


x = DiscreteVariable(:x, 1:5)
y = DiscreteVariable(:y, 2:6)

# BinaryRelation(==, x, y)
# BinaryRelation(==, x, 1)

# Use NodeVariables to break up binary relations like x + y ~ 3 and ternary such as x + y <= z
struct NodeVariable <: Var
    name
    op 
    x
    y
    domain
    booleans
    varmap
end

Base.show(io::IO, var::NodeVariable) = print(io, "$(var.name) = $(var.op)($(var.x), $(var.y))")

find_domain(op, x, y) = sort(collect(Set([op(i, j) for i in domain(x) for j in domain(y)])))

domain(v::Var) = v.domain
booleans(v::Var) = v.booleans

domain(x::Real) = x:x

"All booleans inside an expression that must be added to the encoding"
recursive_booleans(v::NodeVariable) = v.booleans ∪ booleans(v.x) ∪ booleans(v.y)

function NodeVariable(op, x, y, name=gensym())
    domain = find_domain(op, x, y)
    booleans = [Variable(name, i) for i ∈ indices(domain)]
    varmap = Dict(i => v for (i, v) in zip(domain, booleans))
    NodeVariable(name, op, x, y, domain, booleans, varmap)
end



Base.:+(x::Var, y) = NodeVariable(+, x, y)
Base.:+(x, y::Var) = NodeVariable(+, x, y)

Base.:*(x::Var, y) = NodeVariable(*, x, y)
Base.:*(x, y::Var) = NodeVariable(*, x, y)


Base.:^(x::Var, y) = NodeVariable(^, x, y)
Base.:^(x, y::Var) = NodeVariable(^, x, y)


function clauses(var::NodeVariable)

    op = var.op
    x = var.x 
    y = var.y

    clauses = exactly_one(var.booleans)

    # deal with 2 + X
    if x isa Real 
        for j in domain(var.y)
            value = op(x, j)
            # y == j => var == op(x, j)
            push!(clauses, ¬(y.varmap[j]) ∨ var.varmap[value])

        end
   
    # deal with x + 2
    elseif y isa Real 
        for i in domain(var.x)
            value = op(i, y)
            # x == i => var == op(i, y)
            push!(clauses, ¬(x.varmap[i]) ∨ var.varmap[value])

        end
    
    else

        # neither x nor y is real 
        for i in domain(var.x)
            for j in domain(var.y)
                value = op(i, j)
                # x == i && y == j => var == op(i, j)
                push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[j]) ∨ var.varmap[value])
            end
        end

    end

    return clauses

end





Base.:(==)(v::Var, w) = BinaryRelation{==}(v, w)
Base.:(<=)(v::Var, w) = BinaryRelation{<=}(v, w)


"Encode relation like x == 1"
function encode(rel::BinaryRelation{==, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    if y ∉ domain(x)
        error("$y is not in the domain of $x")
    end

    boolean = x.varmap[y]

    return [boolean]
end

"Encode relation like x != 1"
function encode(rel::BinaryRelation{!=, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    if y ∈ domain(x)
        boolean = ¬(x.varmap[y])
    end


    return [boolean]
end

"Encode relation like x == y"
function encode(rel::BinaryRelation{==, <:Var, <:Var})
    x = rel.x 
    y = rel.y 

    clauses = []

    for i in domain(x)
        if i in domain(y)
        # (x == i) => (y == i)  
            push!(clauses, ¬(x.varmap[i]) ∨ (y.varmap[i]))
        
        else
            push!(clauses, ¬(x.varmap[i]))
        end 
    end

    for i in domain(y)
        if i in domain(x)
        # (y == i) => (x == i)  
            push!(clauses, ¬(y.varmap[i]) ∨ (x.varmap[i]))
        
        else
            push!(clauses, ¬(y.varmap[i]))
        end
    end


    return clauses 
end



function encode(rel::BinaryRelation{!=, <:Var, <:Var})
    x = rel.x 
    y = rel.y 

    clauses = []

    for i in domain(x)
        if i in domain(y)
        # (x == i) => (y != i) 
            push!(clauses, ¬(x.varmap[i]) ∨ ¬(y.varmap[i]))
        end
    end


    return clauses 
end




function parse_expression(varmap, ex) 
    op = operation(ex)
    args = arguments(ex)

    new_args = parse_expression.(Ref(varmap), args)

    return op, new_args
end

parse_expression(varmap, ex::Term) = varmap[ex]
parse_expression(varmap, ex::Sym) = varmap[ex]
parse_expression(varmap, ex::Num) = parse_expression(varmap, value(ex))
parse_expression(varmap, ex::Real) = ex


"Parse a symbolic expression into a relation"
function parse_relation(varmap, ex)
    op = operation(ex)
    args = arguments(ex)

    lhs = args[1]
    rhs = args[2]

   
    return BinaryRelation{op}(parse_expression(varmap, lhs), parse_expression(varmap, rhs))

end


# function parse_relation!(varmap, ex::Equation)
    
#     varmap[ex.lhs] = parse_expression(varmap, ex.rhs)   

# end

is_variable(ex) = !istree(ex) || (operation(ex) == getindex)

function process(constraint)

    new_constraints = []

    constraint2 = value(constraint)

    op = operation(constraint2)
    args = arguments(constraint2)

    lhs = args[1]
    rhs = args[2]

    intermediates_generated = false

    if !is_variable(lhs)
        lhs = ReversePropagation.cse_equations(lhs)

        append!(new_constraints, lhs[1])
        lhs = lhs[2]

    end

    if !is_variable(rhs)
        rhs = ReversePropagation.cse_equations(rhs)

        append!(new_constraints, rhs[1])
        rhs = rhs[2]

    end

    # @show new_constraints
    # @show op, lhs, rhs
    push!(new_constraints, op(lhs, rhs))

    return new_constraints

end


process(constraints::Vector) = reduce(vcat, process(constraint) for constraint in constraints)
    



function parse_constraint!(domains, ex)

    expr = value(ex)
    op = operation(expr)

    new_constraints = []

    if op == ∈   # assumes right-hand side is an explicit set specifying the doomain

        args = arguments(expr)

        var = args[1]
        domain = args[2]

        domains[var] = domain

    else
        new_constraints = process(expr)
        
        println()
        # @show expr
        # @show new_constraints

    end

    return domains, new_constraints

end


function parse_constraints(constraints)
    # domains = Dict(var => -Inf..Inf for var in vars)

    additional_vars = []
    domains = Dict()
    all_new_constraints = []  # excluding domain constraints

    for constraint in constraints

        # binarize constraints: 
        domains, new_constraints = parse_constraint!(domains, value(constraint))

        for statement in new_constraints 
            if statement isa Assignment 
                push!(additional_vars, statement.lhs)
            end
        end

        append!(all_new_constraints, new_constraints)
    end

    # append!(additional_vars, keys(domains))

    return domains, all_new_constraints, additional_vars
end




Base.isless(x::Sym, y::Sym) = isless(x.name, y.name)
Base.isless(x::Term, y::Term) = isless(string(x), string(y))
Base.isless(x::Term, y::Sym) = isless(string(x), string(y))
Base.isless(x::Sym, y::Term) = isless(string(x), string(y))

struct ConstraintSatisfactionProblem 
    original_vars 
    additional_vars   # from binarizing
    domains
    constraints 
end

function ConstraintSatisfactionProblem(constraints)

    domains, new_constraints, additional_vars = parse_constraints(constraints)
    @show keys(domains)
    vars = sort(identity.(keys(domains)))
    additional_vars = sort(identity.(additional_vars))

    return ConstraintSatisfactionProblem(vars, additional_vars, domains, new_constraints)
end


struct BoundedIntegerCSP
    original_vars
    additional_vars
    constraints
    varmap   # maps symbolic variables to the corresponding DiscreteVariable
end


BoundedIntegerCSP(constraints) = BoundedIntegerCSP(ConstraintSatisfactionProblem(constraints))

function BoundedIntegerCSP(prob::ConstraintSatisfactionProblem)
    variables = []
    varmap = Dict()

    new_constraints = []

    for (var, domain) in prob.domains
        variable = DiscreteVariable(var, domain)
        push!(variables, variable)
        push!(varmap, var => variable)
    end

    for constraint in prob.constraints 
        constraint = value(constraint)
        if constraint isa Assignment 

            lhs = constraint.lhs

            op, new_args = parse_expression(varmap, constraint.rhs)   # makes a NodeVariable

            # @show op, new_args 

            variable = NodeVariable(op, new_args[1], new_args[2], lhs)
            
            push!(variables, variable)
            push!(varmap, lhs => variable)

        else
            # @show constraint
            push!(new_constraints, parse_relation(varmap, constraint))
        end
    end

    original_vars = [varmap[var] for var in prob.original_vars]
    additional_vars = [varmap[var] for var in prob.additional_vars]
   
    return BoundedIntegerCSP(original_vars, additional_vars, new_constraints, varmap)
end




function encode(prob::BoundedIntegerCSP)
    all_variables = []
    all_clauses = []

    variables = Any[prob.original_vars; prob.additional_vars]
    

    domains = Dict(v.name => v.domain for v in variables)

    for var in variables
        append!(all_variables, var.booleans)
        append!(all_clauses, clauses(var))
    end

    # @show prob.constraints

    for constraint in prob.constraints 
        # @show constraint
        append!(all_clauses, encode(constraint))
    end

    # @show all_variables 
    # @show all_clauses 

    return SymbolicSATProblem(identity.(all_variables), identity.(all_clauses))
end


function solve(prob::BoundedIntegerCSP)
    symbolic_sat_problem = encode(prob)

    status, result_dict = solve(symbolic_sat_problem)

    (status == :unsat) && return status, missing

    # variables = Any[prob.original_vars; prob.additional_vars]
    variables = prob.original_vars

    return status, decode(prob, result_dict)
end

decode(prob::BoundedIntegerCSP, result_dict) = Dict(v.name => decode(result_dict, v) for v in prob.original_vars)
    


function all_solutions(prob::BoundedIntegerCSP)
    sat_problem = encode(prob)
    # variables = Any[prob.original_vars; prob.additional_vars]
    variables = prob.original_vars

    prob2 = encode(prob)
    prob3 = prob2.p   # SATProblem

    sat_solutions = all_solutions(prob3)

    if isempty(sat_solutions)
        return sat_solutions 
    end

    solutions = []

    for solution in sat_solutions
        push!(solutions, decode(prob, decode(prob2, solution)))
    end

    return solutions

end
