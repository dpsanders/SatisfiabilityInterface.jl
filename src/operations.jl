
include("discrete_variables.jl")

"Node in a syntax tree"
struct Node{op}
    lhs
    rhs
    lhs_vars  # vars in the left child 
    rhs_vars
end

vars(n::Node) = n.lhs_vars ∪ n.rhs_vars
Node{op}(x, y) where {op} = Node{op}(x, y, vars(x), vars(y))

import Base: +, ≠, ~

≠(x::DiscreteVariable, y::DiscreteVariable) = Node{≠}(x, y)
~(x::DiscreteVariable, y::DiscreteVariable) = Node{~}(x, y)

+(x::DiscreteVariable, y::DiscreteVariable) = Node{+}(x, y)
+(x::DiscreteVariable, y::Node) = Node{+}(x, y)
+(x::Node, y::DiscreteVariable) = Node{+}(x, y)
+(x::Node, y::Node) = Node{+}(x, y)

~(x, y) = Node{~}(x, y)

x ≠ y
vars(x ≠ y)

function clauses(n::Node{!=})
    # assuming single variables on each side
    clauses = []

    x = n.lhs
    y = n.rhs

    for i in domain(x)
        for j in domain(y)
            # @show i, j
            if i == j 
                push!(clauses, not_both(x.varmap[i], y.varmap[j]))
            end
        end
    end

    return clauses
end


clauses(x ≠ y)


x + y


domain(n::Node{+}) = (tuple(i..., j...) for i in domain(n.lhs) for j in domain(n.rhs))

domain(y)

x + y

domain(x + y) |> collect

domain(x + (y + y)) |> collect


function evaluate(z::Node{op}, x) where {op}  # evaluate z at x
    return op(evaluate(z.lhs, first(x)), evaluate(z.rhs, last(x)))
end

evaluate(z::DiscreteVariable, x) = x
evaluate(z::Int, x) = z

z = x + y

evaluate(z, first(domain(z)))

first(domain(z))

evaluate.(Ref(z), domain(z))


boolean(x::DiscreteVariable, v::Int) = x.varmap[v]

domain(x::Int) = [x]

"""
To encode x + y = n:

- If n is not in domain(x + y) then this is an error / immediately infeasible
- Pairs (x=i, y=j) that are *not* compatible with n are excluded: ¬(x_i ∧ y_j), so ¬x_i ∨ ¬y_j
- Pairs (x=i, y=j) that *are* compatible satisfy x_i => y_{n-i}, i.e.  ¬x_i ∨ y_{n-i}
"""
function clauses(lhs, n::Int)
    # asserts that lhs must be equal to n

    cs = []

    l_vars = vars(lhs)

    for x in domain(lhs)
        x_val = evaluate(lhs, x)
        
        if x_val == n
            x_vars = boolean.(l_vars, x)

            # if have x + y = n then y = x - n,  so x = i => y = x - n
            push!(cs, implies())
        end
    end

    return [∨(cs...)]  # single clause expressing the disjunction

end

function clauses(n::Node{~})

    if n.rhs isa Int   # equal to a constant 
        return clauses(n.lhs, n.rhs)
    end

    cs = []

    l = n.lhs 
        r = n.rhs 

    l_vars = vars(l)
    r_vars = vars(r)

    @show l_vars, r_vars

    # x and y could be tuples like (1, 2):
    for x in domain(l)
        for y in domain(r)

            # @show x, y

            x_val = evaluate(l, x)
            y_val = evaluate(r, y)

            if x_val == y_val

                # @show x, y

                # find the (sets of) Boolean variables encoding the corresponding values of x and y:
                x_vars = boolean.(l_vars, x)
                y_vars = boolean.(r_vars, y)

                @show x_vars, y_vars

                clause = ∨(.¬(x_vars)) ∨ ∨(y_vars)

                # @show clause

                # implies(x, y), i.e. not(x) ∨ y
                # x and/or y given by a collection of variables
                push!(cs, clause)
            end
        end
    end

    return cs

end

z = DiscreteVariable(:z, 3:5)

n = x + y ~ z

clauses(n)

dx_vars = x.booleans

x_vars = [x.booleans[1]]




head((1, 2, 3))

Base.tail((1, 2, 3))

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

constraints = [
    x + y ~ z
]

n = x + y ~ z

clauses(n)

clauses(x ~ 3)

# Want to handle things like 

# x + y + z = 2

# x + (y * z) = 2

# Introduce new variables?

# y + z = u 
# x + u = 2

