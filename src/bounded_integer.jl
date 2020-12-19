"""Symbolic one-hot Boolean encoding of unknown integer value in the range `1:k`.
The value is `i` if `vars[i]` is true and `vars[j]` is false for all j ≠ i.
"""
struct BoundedInteger{k,N,V}
    name::N
    vars::V
end

BoundedInteger{k}(name::N, vars::V) where {k,N,V} = BoundedInteger{k,N,V}(name, vars)

Base.max(x::BoundedInteger{k}) where {k} = k


function BoundedInteger{k}(name) where {k}
    vars = [Variable(Symbol(name, subscript(i))) for i in 1:k]
    
    return BoundedInteger{k}(name, vars)
end

function decode(var_dict, x::BoundedInteger)
    values = [var_dict[v] for v in x.vars]

    num_true = count(values)

    if num_true ≠ 1
        error("Variable $x has not been successfully solved: values $(x.vars .=> values)")
    end

    return findfirst(values)
end


Base.show(io::IO, i::BoundedInteger) = print(io, i.name)

Base.getindex(i::BoundedInteger, n) = i.vars[n]



function clauses(i::BoundedInteger{k}) where {k}
    vars = i.vars

    # takes one of the possible values:
    has_value = [∨(vars...)]

    # but not two simultaneously:
    unique_value = 
        [¬vars[i] ∨ ¬vars[j] for i in 1:k for j in i+1:k]

    return has_value ∪ unique_value 
end





subscript_digit(i) = '₀' + i
subscript(i::Integer) = join(subscript_digit.(reverse(digits(i))))
