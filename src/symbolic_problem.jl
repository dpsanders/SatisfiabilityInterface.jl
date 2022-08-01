using Symbolics: Term

"Index mapping variables to integers"
struct IndexDict
    index::Dict{Num, Int}
end

IndexDict(vars::Vector{<:Num}) = IndexDict(Dict(v => i for (i, v) in enumerate(vars)))



struct SymbolicSATProblem 
    variables # ::Vector{<:Num}
    clauses # ::Vector{<:Term}
    index::IndexDict
    p::SATProblem
end


function process(d::IndexDict, var::Symbolics.Sym)   # process a variable
    # @show d
    if !haskey(d.index, var)
        error("$var is not in the problem")
    end

    return [ d.index[var] ]
end

 
"Output a clause c from a Dict of variables c, as a vector of integers"
# function process(d::IndexDict, clause::Term)
    
#     # @show clause
#     # @show Symbolics.istree(clause.val)

#     if Symbolics.istree(clause.val)
#         term = clause.val
#         if term.f == ¬
#             return [ -(d.index[term.arguments[1]]) ]

#         elseif term.f == ∨
#             return reduce(vcat, process.(Ref(d), term.arguments))

#         else
#             error("$clause is malformed")
#         end

#     else  # variable
#         var = clause  
#         if !haskey(d.index, var)
#             error("$var is not in the problem")
#         end

#         return [ d.index[var] ]
#     end

# end

function process(d::IndexDict, term::Symbolics.Term)
    if term.f == ¬
        return [ -(d.index[term.arguments[1]]) ]        

    elseif term.f == ∨
        return reduce(vcat, process.(Ref(d), term.arguments))

    else
        error("$clause is malformed")
    end
end


"Output a clause c from a Dict of variables c, as a vector of integers"
function process(d::IndexDict, clause::Num)
    
    # @show clause
    # @show Symbolics.istree(clause.val)

    if Symbolics.istree(clause.val)
        term = clause.val
        if term.f == ¬
            return [ -(d.index[term.arguments[1]]) ]

        elseif term.f == ∨
            return reduce(vcat, process.(Ref(d), term.arguments))

        else
            error("$clause is malformed")
        end

    else  # variable
        var = clause  
        if !haskey(d.index, var)
            error("$var is not in the problem")
        end

        return [ d.index[var] ]
    end

end

function process(d::IndexDict, clauses::Vector{Num})
    return process.(Ref(d.index), clauses)
end


function SymbolicSATProblem(variables, symbolic_clauses)  # variables::Vector{<:Num}?

    d = IndexDict(variables)

    clauses = process.(Ref(d), symbolic_clauses)

    p = SATProblem(length(variables), clauses)

    # # @show variables
    # # @show symbolic_clauses
    # # @show d 
    # # @show p 

    return SymbolicSATProblem(variables, symbolic_clauses, d, p)
end

# SymbolicSATProblem(m::Model) = SymbolicSATProblem(boolean_variables(m), clauses(m))



function decode(vars, results::Vector{Int})
    return Dict(v => (i < 0 ? false : true) for (v, i) in zip(vars, results))
end

function solve(p::SymbolicSATProblem)
    status, results = solve(p.p)

    (status == :unsat) && return status, missing

    return status, decode(p.variables, results)

end

decode(p::SymbolicSATProblem, results::Vector{Int}) = decode(p.variables, results)

all_solutions(p::SymbolicSATProblem) = decode.(Ref(p), all_solutions(p.p))
