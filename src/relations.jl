struct BinaryRelation{O, S, T}
    x::S
    y::T 
end

BinaryRelation{O}(x::X, y::Y) where {O,X,Y} = BinaryRelation{O,X,Y}(x, y)


function encode(rel::BinaryRelation{Op, S, T}) where {Op, S, T}
    return encode(Op, rel.x, rel.y)
end


"Encode relation like x == 1"
function encode(::typeof(==), x::Var, j::Real)
    if j ∉ domain(x)
        error("$j is not in the domain of $x")
    end

    boolean = x[j]

    return [boolean]
end

"Encode relation like x != 1"
function encode(::typeof(!=), x::Var, j::Real)

    if j ∈ domain(x)
        boolean = ¬(x[j])
        return [boolean]
    end

    return []
end

"Encode relation like x == y"
function encode(::typeof(==), x::Var, y::Var)
    
    clauses = []

    for i in domain(x)
        if i in domain(y)
        # (x == i) => (y == i)  
            push!(clauses, ¬(x[i]) ∨ (y[i]))
        
        else
            push!(clauses, ¬(x[i]))
        end 
    end

    for i in domain(y)
        if i in domain(x)
        # (y == i) => (x == i)  
            push!(clauses, ¬(y[i]) ∨ (x[i]))
        
        else
            push!(clauses, ¬(y[i]))
        end
    end


    return clauses 
end



function encode(::typeof(!=), x::Var, y::Var)
    
    clauses = []

    for i in domain(x)
        if i in domain(y)
        # (x == i) => (y != i) 
            push!(clauses, ¬(x[i]) ∨ ¬(y[i]))
        end
    end


    return clauses 
end

"Encode relation like x <= 3"
function encode(::typeof(<=), x::Var, j::Real)

    clauses = []

    for i in domain(x)
        if i > j  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses
end

"Encode relation like x < 3"
function encode(::typeof(<), x::Var, j::Real)
    return encode(<=, x, j-1)
end


"Encode relation like x >= 3"
function encode(::typeof(>=), x::Var, j::Real)

    clauses = []

    for i in domain(x)
        if i < j  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses
end

"Encode relation like x > 3"
function encode(::typeof(>), x::Var, j::Real)

    return encode(>=, x, j+1)

end

"Encode relation like x <= y"
function encode(::typeof(<=), x::Var, y::Var)
    
    clauses = []

    for i in domain(x)
        for j in domain(y)

            if i > j  # not possible
                push!(clauses, ¬(x[i]) ∨ ¬(y[j]))
            end

        end
    end

    return clauses 
end

"Encode relation like x < y"
function encode(::typeof(<), x::Var, y::Var)
    
    clauses = []

    for i in domain(x)
        for j in domain(y)

            if i >= j  # not possible
                push!(clauses, ¬(x[i]) ∨ ¬(y[j]))
            end

        end
    end

    return clauses 
end

"Encode relation like x >= y"
function encode(::typeof(>=), x::Var, y::Var)
    return encode(<=, y, x)
end

"Encode relation like x > y"
function encode(::typeof(>), x::Var, y::Var)
    return encode(<, y, x)
end