
# BinaryNode in the Internal Representation

abstract type Node <: Var end 

struct BinaryNode <: Node
    op 
    x
    y
    var   # DiscreteVariable
end

struct UnaryNode <: Node
    op 
    x
    var   # DiscreteVariable
end


Base.show(io::IO, n::BinaryNode) = print(io, "$(n.var.name) = $(n.op)($(n.x), $(n.y))")
Base.show(io::IO, n::UnaryNode) = print(io, "$(n.var.name) = $(n.op)($(n.x))")

find_domain(op, x, y) = sort(collect(Set(op(i, j) for i in domain(x) for j in domain(y))))
find_domain(op, x) = sort(collect(Set(op(i) for i in domain(x))))


Base.getindex(n::Node, i) = n.var[i]

domain(v::Node) = domain(v.var)
booleans(v::Node) = booleans(v.var)
name(v::Node) = name(v.var)

domain(x::Real) = x:x

"All booleans inside an expression that must be added to the encoding"
recursive_booleans(v::BinaryNode) = booleans(v) ∪ booleans(v.x) ∪ booleans(v.y)
recursive_booleans(v::UnaryNode) = booleans(v) ∪ booleans(v.x)


function BinaryNode(op, x, y; name=gensym())
    domain = find_domain(op, x, y)
    
    name = name
    var = DiscreteVariable(name, domain)

    # @show var

    return BinaryNode(op, x, y, var)
end


function UnaryNode(op, x; name=gensym())
    domain = find_domain(op, x)
    
    name = name
    var = DiscreteVariable(name, domain)

    # @show var

    return UnaryNode(op, x, var)
end



Base.:+(x::Var, y) = BinaryNode(+, x, y)
Base.:+(x, y::Var) = BinaryNode(+, x, y)

Base.:*(x::Var, y) = BinaryNode(*, x, y)
Base.:*(x, y::Var) = BinaryNode(*, x, y)


Base.:^(x::Var, y) = BinaryNode(^, x, y)
Base.:^(x, y::Var) = BinaryNode(^, x, y)

Base.:~(x::Var, y) = BinaryNode(~, x, y)
Base.:~(x, y::Var) = BinaryNode(~, x, y)

Base.:abs(x::Var) = UnaryNode(abs, x)
Base.:sign(x::Var) = UnaryNode(sin, x)

# delta(x, y) is 1 iff x == y
# @register_symbolic delta(x::Num, y::Num) false
# @register_symbolic delta(x::Num, y::Int) false

# @register_symbolic delta(x::Num, y::Int) false

@register_symbolic delta(x) 


# delta(x::Int, y::Int) = x == y ? 1 : 0
delta(x::Var) = UnaryNode(delta, x)

delta(x::Int) = x == 0 ? 1 : 0





function clauses(var::BinaryNode)

    op = var.op
    x = var.x 
    y = var.y

    clauses = exactly_one(booleans(var))

    # deal with 2 + X
    if x isa Real 
        for j in domain(y)
            value = op(x, j)
            # y == j => var == op(x, j)
            push!(clauses, ¬(y[j]) ∨ var[value])

        end
   
    # deal with x + 2
    elseif y isa Real 
        for i in domain(x)
            value = op(i, y)
            # x == i => var == op(i, y)
            push!(clauses, ¬(x[i]) ∨ var[value])

        end
    
    else

        # neither x nor y is real 
        for i in domain(var.x)
            for j in domain(var.y)
                value = op(i, j)
                # x == i && y == j => var == op(i, j)
                push!(clauses, ¬(x[i]) ∨ ¬(y[j]) ∨ var[value])
            end
        end

    end

    return clauses

end



function clauses(var::UnaryNode)

    op = var.op
    x = var.x 

    clauses = exactly_one(booleans(var))

    for j in domain(x)
        value = op(j)
            
        push!(clauses, ¬(x[j]) ∨ var[value])

    end
   
    return clauses

end