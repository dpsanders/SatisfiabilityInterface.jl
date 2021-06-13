using Symbolics
using Symbolics: Variable, Sym

include("symbolics_interface.jl")


abstract type Var end   # variable

struct DiscreteVariable{D,B,M} <: Var
    name::Symbol
    domain::D
    booleans::B
    varmap::M  # forward dictionary from domain to variables
end

Base.show(io::IO, x::DiscreteVariable) = print(io, x.name)


DiscreteVariable(name, D) = DiscreteVariable(name, collect(D))

# index integers as themselves; otherwise just 1..n:
indices(v::Vector{Int}) = v
indices(v) = collect(eachindex(v))

function DiscreteVariable(name, domain::Vector)
    booleans = [Variable(name, i) for i ∈ indices(domain)]
    varmap = Dict(i => v for (i, v) in zip(domain, booleans))

    return DiscreteVariable(name, domain, booleans, varmap)
end


not_both(x, y) = ¬x ∨ ¬y
implies(x, y) = ¬x ∨ y

"Given a set of boolean variables, gives clauses specifying that exactly one of them is true"
function exactly_one(vars)
    clauses = [∨(vars...)]   # one must be true

    # two cannot be true: 
    for i in 1:length(vars)
        for j in i+1:length(vars)
            push!(clauses, not_both(vars[i], vars[j]))  
        end
    end

    return clauses
end

clauses(x::DiscreteVariable) = exactly_one(x.booleans)
   

domain(x::DiscreteVariable) = x.domain
vars(x::DiscreteVariable) = [x]


colours = [:red, :yellow, :blue]

x = DiscreteVariable(:x, colours)
y = DiscreteVariable(:y, 2:4)

clauses(x)
clauses(y)

domain(x)
vars(x)


