using Symbolics: Assignment, get_variables, operation, arguments, value

include("discrete_variables.jl")

#= 
High-level idea: 
Rewrite expressions to use only binary variables 

E.g. x + y + z + w ≤ 3

is rewritten to 

x + y = u1
u1 + y = u2
u2 + w ≤ 3

One way (?) to handle this is to make u1 and u2 new DiscreteVariables,
whose domains should be discovered.

We need to generate clauses for expressions of two types:

(i)   x + y = z   for a variable z
(ii)  x + y = n   for a constant n 

[Initially it would seem like we could eliminate a variable instead, 
but since we're adding new variables anyway this is probably not a good idea?]

We also need a way to specify
x = n   for a constant n

Treat booleans as integer variables with range 0:1
For booleans we need 
x = ¬y  

z = x + y 
can define a new variable z of type OperationVariable 




=#





# x = DiscreteVariable(:x, 1:3)
# y = DiscreteVariable(:y, 2:4)

# clauses(x ≠ y)

# colours = [:red, :green, :blue]

# x = DiscreteVariable(:x, colours)
# y = DiscreteVariable(:y, colours)

# clauses(x ≠ y)


# domain(n::Node{+}) = (tuple(i..., j...) for i in domain(n.lhs) for j in domain(n.rhs))

# domain(y)

# x + y

# domain(x + y) |> collect

# domain(x + (y + y)) |> collect


# function evaluate(z::Node{op}, x) where {op}  # evaluate z at x
#     return op(evaluate(z.lhs, first(x)), evaluate(z.rhs, last(x)))
# end

# evaluate(z::DiscreteVariable, x) = x
# evaluate(z::Int, x) = z

# z = x + y

# evaluate(z, first(domain(z)))

# first(domain(z))

# evaluate.(Ref(z), domain(z))


# boolean(x::DiscreteVariable, v::Int) = x.varmap[v]

# domain(x::Int) = [x]

# """
# To encode x + y = n:

# - If n is not in domain(x + y) then this is an error / immediately infeasible
# - Pairs (x=i, y=j) that are *not* compatible with n are excluded: ¬(x_i ∧ y_j), so ¬x_i ∨ ¬y_j
# - Pairs (x=i, y=j) that *are* compatible satisfy x_i => y_{n-i}, i.e.  ¬x_i ∨ y_{n-i}
# """


# z = DiscreteVariable(:z, 3:5)

# n = x + y ~ z

# clauses(n)

# dx_vars = x.booleans

# x_vars = [x.booleans[1]]




# head((1, 2, 3))

# Base.tail((1, 2, 3))

#= Sum constraint

Consider the constraint x + y = z

If x_i is true then "x = i", i.e. x has the value i

So if x_i and y_j then z must have value i+j 

    i.e. x_i ∧ y_j => z_{i+j}

    i.e. ¬(x_i ∧ y_j ∧ ¬z_{i+j})

    so  ¬x_i ∨ ¬y_j ∨ z_{i+j}

    (The contrapositive is taken account of by the clauses that specify that at most one of the x's / y's / z's is 1)


=#



#= 
Example from BeeEncoder.jl:

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

x = DiscreteVariable(:x, 0:5)
y = DiscreteVariable(:y, -4:9)
z = DiscreteVariable(:z, -5:10)
w = DiscreteVariable(:w, 0:10)

# constraints = [
#     x + y ~ z
# ]

# n = x + y ~ z

# clauses(n)

# clauses(x ~ 3)

# Want to handle things like 

# x + y + z = 2

# x + (y * z) = 2

# Introduce new variables?

# y + z = u 
# x + u = 2

#########

# function make_variable(name, op, x, y)

#     s = Set()
#     clauses = []
    
#     for i in domain(x)
#         for j in domain(y)
#             value = op(i, j)

#             push!(s, value)
#         end
#     end

#     z_variable = DiscreteVariable(name, identity.(s))

#     return z_variable
# end

"Find the domain of op(x, y), assuming that x and y have *finite* domains.
We could (possibly / partially?) relax this using interval arithmetic.
"

# function find_domain(op, x, y)
#     @show op, x, y
#     s = Set(op(i, j) for i ∈ domain(x), j ∈ domain(y))
#     return sort(collect(s))
# end

find_domain(domains, op, x, y) = op(domains[x], domains[y])

    #     s = Set(op(i, j) for i ∈ domain(x), j ∈ domain(y))
    #     return sort(collect(s))
    # end

x = DiscreteVariable(:x, 0:5)
y = DiscreteVariable(:y, -4:9)

using IntervalArithmetic

intervalise(domain) = interval(extrema(domain)...)

# X = intervalise(domain(x))
# Y = intervalise(domain(y))

# +(X, Y)
# *(X, Y)

# find_domain(+, x, y)
# find_domain(*, x, y)





# function process(ex::Assignment)
#     variable = ex.lhs

#     rhs = value(ex.rhs)

#     op = operation(rhs)
#     args = arguments(rhs)
    
#     # if !isdefined(@__MODULE__, variable)
#     #     @variables $variable
#     # end

#     return make_variable(variable, op, args...)

# end


# @variables x, y, z



# ex = Assignment(z, x + y)

# process(ex)


x = DiscreteVariable(:x, 1:2)
y = DiscreteVariable(:y, 3:5)

# z = OperationVariable(:z, +, x, y)

# z = make_variable(:z, +, x, y

# ex = Assignment(z, x + y)

# process(ex)

#= 
Contradiction between treating x + y as purely symbolic, and as referring to actual variables
=#

@variables x, y, z 

constraints = [
    x ∈ 1:4
    y ∈ 2:5
    z == x + y
    z ≤ 4
]

#=
The constraint z == x + y feels different, since it introduces a new variable.
But it's really the same (?) if z is already defined symbolically

To each symbolic variable there should be a DiscreteVariable with that name.
But we should not have x = DiscreteVariable(...)

1. Start off with a *purely* symbolic description
2. Translate into a constraint satisfaction problem with DiscreteVariables with known domains and only binary operations (?)
3. Encode to Boolean CNF

=#

x ∈ 1:4



#=
Start off with domains as -Inf..Inf
=#


Base.intersect(x::Interval, y::UnitRange) = x ∩ interval(extrema(y)...)



function parse_constraint!(domains, ex::Num)
    expr = value(ex)
    op = operation(expr)

    args = arguments(expr)
    lhs = args[1]
    rhs = args[2]

    binary_constraint = false

    if op == ∈
        var = lhs
        domain = rhs 

        @show var
        @show domain

        domains[var] = domains[var] ∩ domain
    
    elseif (op == ==) || (op == ~)
        var = lhs 
        op = operation(rhs)
        variables = arguments(rhs)

        @show op, 
        @show variables, typeof(variables)

        domains[var] = find_domain(domains, op, variables...)

        binary_constraint = true
    
    elseif (op == <) || (op == ≤)
        domains[lhs] = domains[lhs] ∩ interval(-Inf, rhs)

    elseif (op == >) || (op == ≥)
        domains[lhs] = domains[lhs] ∩ interval(rhs, Inf)
    end

    return domains, binary_constraint

end



@variables x, y, z
domains = Dict(value(x) => -Inf..Inf, value(y) => -Inf..Inf, value(z) => -Inf..Inf)

parse_constraint!(domains, x ∈ 1:2)
parse_constraint!(domains, y ∈ 2:5)
domains[x]

parse_constraint!(domains, z == x + y)
parse_constraint!(domains, z ≤ 4)
parse_constraint!(domains, z ≤ 3)

domain(x::Sym) = domains[x]

#=
Once we have parsed all the constraints, we are ready to create the true 
ConstraintSatisfactionProblem
=#



function parse_constraints(vars, constraints)
    domains = Dict(var => -Inf..Inf for var in vars)
    binary_constraints = []

    for constraint in constraints 
        domains, is_binary = parse_constraint!(domains, constraint)
        if is_binary
            push!(binary_constraints, constraint)
        end
    end

    return domains, binary_constraints
end


varss = @variables x, y, z 

constraints = [
    x ∈ 1:4
    y ∈ 2:5
    z == x + y
    z ≤ 4
]

domains, binary_constraints = parse_constraints(varss, constraints)

domains
binary_constraints



struct ConstraintSatisfactionProblem 
    vars 
    domains
    constraints 
    varmap
end

function ConstraintSatisfactionProblem(vars, constraints)
    domains, binary_constraints = parse_constraints(varss, constraints)

    return ConstraintSatisfactionProblem(vars, domains, binary_constraints, Dict())
end


varss = @variables x, y, z 

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z == x + y
    z ≤ 4
]

prob = ConstraintSatisfactionProblem(varss, constraints)

prob.vars
prob.domains
prob.constraints

#= I've lost the information that the domains are discrete!

Make domain_bounds be intervals, and domain_type record whether real or integer
=#