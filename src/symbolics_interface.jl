

@register ∨(x, y)   # \wedge
@register ∧(x, y)   # \vee
@register ¬(x)      # \neg

# @register ∨(x...)
# @register ∨(x::AbstractVector{T} where T)

const DiscreteTypes = Union{Integer, Symbol}

@register Base.:∈(x, y::AbstractRange{T} where T<:DiscreteTypes)
@register Base.:∈(x, y::UnitRange{T} where T<:DiscreteTypes) false  # false prevents defining 
@register Base.:∈(x, y::AbstractVector{T} where T<:DiscreteTypes) false
@register Base.:∈(x, y::Vector{T} where T<:DiscreteTypes) false
@register Base.:∈(x, y::Tuple) false

# TODO: Varargs ∨


∨(x::Vector{T}) where {T} = isempty(x) ? T[] : ∨(x...)


∨(x...) = foldl(∨, x)
# ∨(x...) = Symbolics.Term(∨, [x...])
∧(x...) = foldl(∧, x)

