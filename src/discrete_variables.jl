

abstract type Var end   # variable

struct DiscreteVariable{N,D,B,M} <: Var
    name::N
    domain::D
    booleans::B
    varmap::M  # forward dictionary from domain to variables
end

name(v::DiscreteVariable) = v.name
domain(v::DiscreteVariable) = v.domain
booleans(v::DiscreteVariable) = v.booleans

# Base.show(io::IO, x::DiscreteVariable) = print(io, "Variable $(x.name) ∈ $(x.domain)")
Base.show(io::IO, x::DiscreteVariable) = print(io, "variable $(x.name)")

Base.getindex(v::DiscreteVariable, i) = v.varmap[i]

DiscreteVariable(name, D) = DiscreteVariable(name, sort(collect(D)))

# index integers as themselves; otherwise just 1..n:
indices(v::Vector{Int}) = v
indices(v) = collect(eachindex(v))


function DiscreteVariable(name, domain::Vector)
    booleans = [Symbolics.variable(name, i) for i ∈ indices(domain)]
    varmap = Dict(i => v for (i, v) in zip(domain, booleans))

    return DiscreteVariable(name, domain, booleans, varmap)
end


not_both(x, y) = ¬x ∨ ¬y
implies(x, y) = ¬x ∨ y
and(x, y) = ¬(¬x ∨ ¬y)


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

clauses(x::DiscreteVariable) = exactly_one(booleans(x))
   

# domain(x::Var) = x.domain
# vars(x::DiscreteVariable) = [x]



function decode(varmap, x::Var)
    values = [varmap[v] for v in booleans(x)]

    num_true = count(values)

    if num_true ≠ 1
        error("Variable $x has not been successfully solved: values $(x.vars .=> values)")
    end

    which = findfirst(values)  # find first (and only) one which is true
    return x.domain[which]  # map it back to the domain
end

