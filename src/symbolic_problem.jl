using Symbolics: Term

"Index mapping variables to integers"
struct IndexDict
    index::Dict{Sym, Int}
end

IndexDict(vars::Vector{<:Sym}) = IndexDict(Dict(v => i for (i, v) in enumerate(vars)))



struct SymbolicSATProblem 
    variables # ::Vector{<:Sym}
    clauses # ::Vector{<:Term}
    index::IndexDict
    p::SATProblem
end


function process(d::IndexDict, var::Sym)
    if !haskey(d.index, var)
        error("$var is not in the problem")
    end

    return [ d.index[var] ]
end

 
"Output a clause c from a Dict of variables c, as a vector of integers"
function process(d::IndexDict, clause::Term)

    if clause.f == ¬
        return [ -(d.index[clause.arguments[1]]) ]

    elseif clause.f == ∨
        return reduce(vcat, process.(Ref(d), clause.arguments))

    else
        error("Malformed")
    end

end

function process(d::IndexDict, clauses)
    return process.(Ref(d.index), clauses)
end


function SymbolicSATProblem(variables::Vector{<:Sym}, symbolic_clauses)

    d = IndexDict(variables)

    clauses = process.(Ref(d), symbolic_clauses)

    p = SATProblem(length(variables), clauses)

    # @show variables
    # @show symbolic_clauses
    # @show d 
    # @show p 

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
