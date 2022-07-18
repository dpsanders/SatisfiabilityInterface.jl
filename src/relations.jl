





struct BinaryRelation{O, S, T}
    x::S
    y::T 
end

BinaryRelation{O}(x::X, y::Y) where {O,X,Y} = BinaryRelation{O,X,Y}(x, y)





Base.:(==)(v::Var, w) = BinaryRelation{==}(v, w)
Base.:(<=)(v::Var, w) = BinaryRelation{<=}(v, w)


"Encode relation like x == 1"
function encode(rel::BinaryRelation{==, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    if y ∉ domain(x)
        error("$y is not in the domain of $x")
    end

    boolean = x[y]

    return [boolean]
end

"Encode relation like x != 1"
function encode(rel::BinaryRelation{!=, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    if y ∈ domain(x)
        boolean = ¬(x[y])
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



function encode(rel::BinaryRelation{!=, <:Var, <:Var})
    x = rel.x 
    y = rel.y 

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
function encode(rel::BinaryRelation{<=, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    clauses = []

    for i in domain(x)
        if i > y  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses
end

"Encode relation like x < 3"
function encode(rel::BinaryRelation{<, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    clauses = []

    for i in domain(x)
        if i >= y  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses

end


"Encode relation like x >= 3"
function encode(rel::BinaryRelation{>=, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    clauses = []

    for i in domain(x)
        if i < y  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses
end

"Encode relation like x > 3"
function encode(rel::BinaryRelation{>, <:Var, <:Real})

    x = rel.x 
    y = rel.y

    clauses = []

    for i in domain(x)
        if i <= y  # not possible
            push!(clauses, ¬(x[i]))
        end
    end

    return clauses

end