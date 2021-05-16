using Revise, ModelingToolkit

include("modeling_toolkit_interface.jl")

abstract type Var end   # variable

# struct Boolean 
#     name::Symbol
# end

# OR(x::Boolean, y::Boolean) = 

struct Integ <: Var
    name::Symbol
    domain::Vector{Int}
    booleans::Vector{Sym{Real}}
    varmap::Dict{Int, Sym{Real}}  # forward dictionary from domain to variables
end

Base.show(io::IO, x::Integ) = print(io, x.name)


function Integ(name, domain)
    domain2 = collect(domain)
    booleans = [Variable(name, i) for i ∈ domain2]

    varmap = Dict(i => v for (i, v) in zip(domain2, booleans))

    return Integ(name, domain2, booleans, varmap)
end


not_both(x, y) = ¬x ∨ ¬y


function clauses(x::Integ)
    vars = x.booleans

    cs = [∨(vars...)]  # one must be true

    for i in 1:length(vars)
        for j in i+1:length(vars)
            push!(cs, not_both(vars[i], vars[j]))  # not both are true 
        end
    end

    return cs

end

x = Integ(:x, 1:4)
y = Integ(:y, 2:6)

clauses(y)


domain(x::Integ) = x.domain
vars(x::Integ) = [x]

vars(x::Int) = []

domain(x)

vars(x)

struct Node{op}
    lhs
    rhs
    l_vars  # vars in the left child 
    r_vars
end

vars(n::Node) = n.l_vars ∪ n.r_vars
Node{op}(x, y) where {op} = Node{op}(x, y, vars(x), vars(y))

import Base: +, ≠, ~

≠(x::Integ, y::Integ) = Node{≠}(x, y)
~(x::Integ, y::Integ) = Node{~}(x, y)

+(x::Integ, y::Integ) = Node{+}(x, y)
+(x::Integ, y::Node) = Node{+}(x, y)
+(x::Node, y::Integ) = Node{+}(x, y)
+(x::Node, y::Node) = Node{+}(x, y)

~(x, y) = Node{~}(x, y)

x ≠ y
vars(x ≠ y)

function clauses(n::Node{!=})
    # assuming single variables on each side
    cs = []

    x = n.lhs
    y = n.rhs

    for i in domain(x)
        for j in domain(y)
            @show i, j
            if i == j 
                push!(cs, not_both(x.varmap[i], y.varmap[j]))
            end
        end
    end

    return cs
end


clauses(x ≠ y)


x + y


domain(n::Node{+}) = [tuple(i..., j...) for i in domain(n.lhs) for j in domain(n.rhs)]

domain(y)

x + y

domain(x + y)

domain(x + (y + y)) |> collect


function evaluate(z::Node{op}, x) where {op}  # evaluate z at x
    return op(evaluate(z.lhs, first(x)), evaluate(z.rhs, last(x)))
end

evaluate(z::Integ, x) = x
evaluate(z::Int, x) = z

z

evaluate(z, first(domain(z)))

first(domain(z))

evaluate.(Ref(z), domain(z))


boolean(x::Integ, v::Int) = x.varmap[v]

domain(x::Int) = [x]


function clauses(lhs, n::Int)
    # asserts that lhs must be equal to r
    cs = []

    l_vars = vars(lhs)

    for x in domain(lhs)
        x_val = evaluate(lhs, x)
        
        if x_val == n
            x_vars = boolean.(l_vars, x)

            # if have x + y = n then y = x - n,  so x = i => y = x - n
            
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

z = Integ(:z, 3:5)

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

x = Integ(:x, 0:5)
y = Integ(:y, -4:9)
z = Integ(:z, -5:10)
w = Integ(:w, 0:10)

constraints = [
    x + y ~ z
]

n = x + y ~ z

clauses(n)

clauses(x ~ 3)
