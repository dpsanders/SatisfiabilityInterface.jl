

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

find_domain(domains, op, x, y) = Set([op(i, j) for i in domains[x] for j in domains[y]])

find_domain(op, x, y) = Set([op(i, j) for i in domain(x) for j in domain(y)])


# IntervalArithmetic version:
# find_domain(domains, op, x, y) = op(domains[x], domains[y]) 

 
# using IntervalArithmetic

# intervalise(domain) = interval(extrema(domain)...)

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

# z = OperationVariable(:z, +, x, y)

# z = make_variable(:z, +, x, y

# ex = Assignment(z, x + y)

# process(ex)

#= 
Contradiction between treating x + y as purely symbolic, and as referring to actual variables
=#

# @variables x, y, z 

# constraints = [
#     x ∈ 1:4
#     y ∈ 2:5
#     z == x + y
#     z ≤ 4
# ]

#=
The constraint z == x + y feels different, since it introduces a new variable.
But it's really the same (?) if z is already defined symbolically

To each symbolic variable there should be a DiscreteVariable with that name.
But we should not have x = DiscreteVariable(...)

1. Start off with a *purely* symbolic description
2. Translate into a constraint satisfaction problem with DiscreteVariables with known domains and only binary operations (?)
3. Encode to Boolean CNF

=#

# x ∈ 1:4



#=
Start off with domains as -Inf..Inf
=#


# Base.intersect(x::Interval, y::UnitRange) = x ∩ interval(extrema(y)...)



function parse_constraint!(domains, ex)

    expr = value(ex)
    op = operation(expr)

    args = arguments(expr)
    lhs = args[1]
    rhs = args[2]

    # some constraints just specify domains; exclude these
    relational_constraint = true

    if op == ∈   # assumes right-hand side is an explicit set specifying the doomain
        var = lhs
        domain = rhs 

        # @show var
        # @show domain

        # domains[var] = domains[var] ∩ domain
        domains[var] = domain
        relational_constraint = false
    
    # elseif (op == ==) || (op == ~)
    #     var = lhs 
    #     op = operation(rhs)
    #     variables = arguments(rhs)

    #     # @show op, 
    #     # @show variables, typeof(variables)

    #     domains[var] = find_domain(domains, op, variables...)
    
    # elseif (op == <) || (op == ≤)
    #     domains[lhs] = domains[lhs] ∩ interval(-Inf, rhs)

    # elseif (op == >) || (op == ≥)
    #     domains[lhs] = domains[lhs] ∩ interval(rhs, Inf)
    
    end

    return domains, relational_constraint

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

function parse_constraints(vars, constraints)
    # domains = Dict(var => -Inf..Inf for var in vars)
    domains = Dict()
    relational_constraints = []  # excluding domain constraints

    for constraint in constraints 
        domains, is_relation = parse_constraint!(domains, value(constraint))
        if is_relation
            push!(relational_constraints, constraint)
        end
    end

    return domains, relational_constraints
end



struct ConstraintSatisfactionProblem 
    vars 
    domains
    constraints 
    varmap
end

function ConstraintSatisfactionProblem(vars, constraints)

    # flatten constraints:

    # while true 
    #     new_constraints = Iterators.flatten(constraints)
    #     if new_constraints == constraints 
    #         break 
    #     end
    # end


    domains, binary_constraints = parse_constraints(vars, constraints)

    return ConstraintSatisfactionProblem(vars, domains, binary_constraints, Dict())
end



#= We've lost the information that the domains are discrete!

Make domain_bounds be intervals, and domain_type record whether real or integer
=#