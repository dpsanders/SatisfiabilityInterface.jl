# Modified from ReversePropagation.jl (MIT license)

## Common Subexpression Elimination (CSE)


"""Do common subexpression elimination on the expression `ex`, 
by traversing it recursively and reducing to binary operations.

Modifies the `OrderedDict` `dict`.
"""
function cse!(dict, ex)

    if istree(ex)
        
        args = arguments(ex)
        op = operation(ex)

        if length(args) == 1 

            left  = cse!(dict, args[1])

            ex = op(left)

        elseif length(args) == 2 

            left  = cse!(dict, args[1])
            right = cse!(dict, args[2])

            ex = op(left, right)

        else
            left  = cse!(dict, args[1])
            right = cse!(dict, op(args[2:end]...))   # use similarterm?

            ex = op(left, right)

        end

        if haskey(dict, ex)
            return dict[ex]

        else
            val = make_variable()
            push!(dict, ex => val)
        end

        return val
    
    else  # not a tree
        return ex
    end

end

"Do CSE on an expression"
function cse(ex)
    dict = OrderedDict()
    final = cse!(dict, ex)

    return dict, final 
end

"Flatten a nested expression to a chain of unary or binary operations"
function flatten_expression(ex) 
    dict, final = cse(ex) 

    return [Assignment(rhs, lhs) for (lhs, rhs) in pairs(dict)], final
end

"Flatten a nested expression to a chain of unary or binary operations"
flatten_expression(ex::Num) = cse(Symbolics.value(ex))

