

@register ∨(x, y)   # \wedge
@register ∧(x, y)   # \vee
@register ¬(x)      # \neg

∨(x::Vector{T}) where {T} = isempty(x) ? T[] : ∨(x...)


∨(x...) = foldl(∨, x)
∧(x...) = foldl(∧, x)
