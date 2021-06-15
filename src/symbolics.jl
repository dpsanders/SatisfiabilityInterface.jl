using Symbolics

@register Base.:∈(x, y::Any)
@register ∨(x::Sym...)

struct Integers end

const ℤ = Integers()


@variables x, y

y ∈ ℤ

