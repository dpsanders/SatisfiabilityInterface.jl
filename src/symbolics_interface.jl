

@register ∨(x, y)   # \wedge
@register ∧(x, y)   # \vee
@register ¬(x)      # \neg

@register ∨(x...)
@register ∨(x::AbstractVector{T} where T)

@register Base.:∈(x, y::AbstractRange{T} where T<:Integer)
@register Base.:∈(x, y::UnitRange{T} where T<:Integer)
@register Base.:∈(x, y::AbstractVector{T} where T<:Integer)
@register Base.:∈(x, y::Tuple)

# TODO: Varargs ∨


∨(x::Vector{T}) where {T} = isempty(x) ? T[] : ∨(x...)


∨(x...) = foldl(∨, x)
∧(x...) = foldl(∧, x)
