

@register ∨(x, y)   # \wedge
@register ∧(x, y)   # \vee
@register ¬(x)      # \neg

∨(x...) = foldl(∨, x)
∧(x...) = foldl(∧, x)