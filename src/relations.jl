using Base: notify_fun


using Symbolics
using Symbolics: Sym, value, operation, arguments, istree, Assignment

include("discrete_variables.jl")
include("symbolics_interface.jl")

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

u = NodeVariable(+, x, y)

Base.:+(x::Var, y) = NodeVariable(+, x, y)
Base.:+(x, y::Var) = NodeVariable(+, x, y)

Base.:*(x::Var, y) = NodeVariable(*, x, y)
Base.:*(x, y::Var) = NodeVariable(*, x, y)


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



z = x + y

w = x + z

# BinaryRelation(==, w, 3)

booleans(w)

booleans(z)

recursive_booleans(w)




Base.:(==)(v::Var, w) = BinaryRelation{==}(v, w)
Base.:(<=)(v::Var, w) = BinaryRelation{<=}(v, w)

x + z <= 1

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



encode(x + z == 5)
encode(x + z + z == 7)

domain(x + z + z)

parse_expression(varmap, ex::Real) = ex
parse_expression(varmap, ex::Sym) = varmap[ex]

function parse_expression(varmap, ex) 
    op = operation(ex)
    args = arguments(ex)

    new_args = parse_expression.(Ref(varmap), args)

    return op(new_args...)
end

parse_expression(varmap, ex::Num) = parse_expression(varmap, value(ex))


"Parse a symbolic expression into a relation"
function parse_relation(varmap, ex)
    op = operation(ex)
    args = arguments(ex)

    lhs = args[1]
    rhs = args[2]

   
    return BinaryRelation{op}(parse_expression(varmap, lhs), parse_expression(varmap, rhs))

end

function parse_relation!(varmap, ex::Equation)
    
    varmap[ex.lhs] = parse_expression(varmap, ex.rhs)   

end

# parse_relation!(varmap, ex::Num) = parse_relation!(varmap, value(ex))

# @variables x, y

# varmap = Dict()
# varmap[x] = DiscreteVariable(:x, 1:5)
# varmap[y] = DiscreteVariable(:y, 2:6)

# parse_expression(varmap, x + y)


# parse_relation!(varmap, z ~ x + y)


# parse_relation!(varmap, z <= x + y*x)

# parse_relation!(varmap, x + y == 3)

# encode(ans)

#=
The difference between z ~ x + y and z == x + y is whether the domain of z is already fixed.
z ~ x + y means that z is defined in that way

(z must still be declared with @variable though)
=#

# domain(varmap[x] + varmap[y])


using ReversePropagation

@variables x, y, w, z
ex = x + y
ReversePropagation.cse_equations(ex)


function process(constraint)

    new_constraints = []

    constraint2 = value(constraint)

    op = operation(constraint2)
    args = arguments(constraint2)

    lhs = args[1]
    rhs = args[2]

    if istree(lhs)
        lhs = ReversePropagation.cse_equations(lhs)
    end

    if istree(rhs)
        rhs = ReversePropagation.cse_equations(rhs)
    end

    if length(lhs) > 1  # intermediate variables were generated 
        append!(new_constraints, lhs[1])
        lhs = lhs[2]
    end

    if length(rhs) > 1  # intermediate variables were generated 
        append!(new_constraints, rhs[1])
        rhs = rhs[2]
    end

    @show new_constraints
    @show op, lhs, rhs
    push!(new_constraints, op(lhs, rhs))

    return new_constraints

end

constraint = x + y <= 1
lhs, rhs = process(constraint)


constraint = x + y <= w + z
lhs, rhs = process(constraint)

constraint = x + y + w + z == w
lhs, rhs = process(constraint)

constraint = b[1] + b[2] + b[3] + b[4] == w
constraint
typeof(constraint)

typeof((w + x + y + z) == w)

lhs, rhs = process(constraint)


constraints = [
    # x ∈ 1:2
    # y ∈ 2:5
    # z ∈ 3:7
    # w ∈ 4:4
    z == x * y
    z ≠ w
]

process(constraints::Vector) = reduce(vcat, process(constraint) for constraint in constraints)
    
process(constraints)

for constraint in constraints 
    @show constraint
    @show process(constraint)
end

# @edit @variables x





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
        @show expr
        @show new_constraints

    end

    return domains, new_constraints

end


#=
Once we have parsed all the constraints, we are ready to create the true 
ConstraintSatisfactionProblem
=#

## TODO
# Handle unary constraints like z <= x 
# Handle z == 2
# Handle x + y == 2   
# Handle x + y <= 4   (probably add a new variable z = x + y)

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




# domains, new_constraints, additional_vars = parse_constraints(constraints)

# domains

# new_constraints

Base.isless(x::Sym, y::Sym) = isless(x.name, y.name)

struct ConstraintSatisfactionProblem 
    original_vars 
    additional_vars   # from binarizing
    domains
    constraints 
end

function ConstraintSatisfactionProblem(constraints)

    domains, new_constraints, additional_vars = parse_constraints(constraints)
    vars = sort(identity.(keys(domains)))
    additional_vars = sort(identity.(additional_vars))

    return ConstraintSatisfactionProblem(vars, additional_vars, domains, new_constraints)
end


prob = ConstraintSatisfactionProblem(constraints)

prob.domains

struct BoundedIntegerCSP
    original_vars
    additional_vars
    constraints
    varmap   # maps symbolic variables to the corresponding DiscreteVariable
end

# varmap gives the translation from strictly symbolic objects to actual Julia objects

# get_bounds(x::Interval) = ceil(Int, x.lo):floor(Int, x.hi)


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
            new_var = constraint.lhs

            variable = parse_expression(varmap, constraint.rhs)   # makes a NodeVariable
            push!(variables, variable)
            push!(varmap, new_var => variable)

        else
            @show constraint
            push!(new_constraints, parse_relation(varmap, constraint))
        end
    end

    original_vars = [varmap[var] for var in prob.original_vars]
    additional_vars = [varmap[var] for var in prob.additional_vars]
   
    return BoundedIntegerCSP(original_vars, additional_vars, new_constraints, varmap)
end


prob2 = BoundedIntegerCSP(constraints)

include("sat_problem.jl")
include("symbolic_problem.jl")
include("solver.jl")

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
        @show constraint
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

decode(prob::BoundedIntegerCSP, result_dict) = [v => decode(result_dict, v) for v in prob.original_vars]
    


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



constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
    z ≠ 4
]

prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)

solve(prob3)

solve(prob2)

prob2.additional_vars[1].domain


constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
]


prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)
prob4 = prob3.p

solve(prob3)
solve(prob2)

solns = all_solutions(prob4)
all_solutions(prob3)

### 

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y + x
    x > 1
]



prob = BoundedIntegerCSP(constraints)
all_solutions(prob)




### BeeEncoder example

#=
@beeint x  0 5
@beeint y -4 9
@beeint z -5 10

@constrain x + y == z

@beeint w 0 10

xl = @beebool x[1:4]

@constrain xl[1] == -xl[2]
@constrain xl[2] == true

@constrain sum([-xl[1], xl[2], -xl[3], xl[4]]) == w
=#

@variables x, y, z, w
b = Num.(Variable.(:b, 1:4))
@variables c, d

constraints = [
    x ∈ 0:5
    y ∈ -4:9
    z ∈ -5:10
    w ∈ 0:10
    b .∈ Ref(0:1)  # boolean
    c ∈ 0:1
    d ∈ 0:1
    x + y == z
    b[1] + b[2] == 1
    b[2] == 1
    c + b[1] == 1   # encode c = ¬b[1]
    d + b[3] == 1

    c + b[2] + d + b[4] == w
    # sum(b) == w

]


prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)

status, results = solve(prob3)

decode(prob2, results)

solve(prob2)

prob2.original_vars

all_solutions(prob2)



constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == 2y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
solve(prob)

all_solutions(prob)

prob.additional_vars



constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == -y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
solve(prob)
all_solutions(prob)


constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == -2y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
all_solutions(prob)
