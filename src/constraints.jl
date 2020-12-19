
struct Constraint{op,L,R}
    lhs::L
    rhs::R
end

Constraint{op}(lhs::L, rhs::R) where {op, L, R} = Constraint{op,L,R}(lhs, rhs)

function print_op(op)
    (op == ≠) && return "≠"
    (op == ~) && return "="
end

Base.show(io::IO, c::Constraint{op}) where {op} = print(io, c.lhs, " ", print_op(op), " ", c.rhs)


function clauses(c::Constraint{!=})

    # ¬(x[i] ∧ y[i])  -- can't take same value

    [¬(c.lhs[i]) ∨ ¬(c.rhs[i]) for i in 1:min(max(c.lhs), max(c.rhs))]
end


function clauses(c::Constraint{~})
    i = c.rhs  # integer 
    [c.lhs[i]]  # that Boolean is positive
end

Base.:≠(x::BoundedInteger, y::BoundedInteger) = Constraint{≠}(x, y)
Base.:~(x::BoundedInteger, y::Int) = Constraint{~}(x, y)



macro integer(name, k)
    quoted = Meta.quot(name)

    :($(esc(name)) = BoundedInteger{$k}($quoted))
end


make_vector(name, T, num) = [T(Symbol(name, subscript(i))) for i in 1:num]


