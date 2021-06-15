include("constraints.jl")


struct Model
    variables
    constraints
end

Model() = Model([], [])

# Base.push!(m::Model, var) = push!(m.variables, var)
# Base.push!(m::Model, c::Constraint) = push!(m.constraints, c)

function clauses(m::Model)
    variable_clauses = reduce(∪, clauses.(m.variables))
    constraint_clauses = reduce(∪, clauses.(m.constraints))

    return variable_clauses ∪ constraint_clauses
end

variables(m::Model) = m.variables
# boolean_variables(m::Model) = reduce(vcat, (v.vars for v in variables(m)))
boolean_variables(m::Model) = reduce(vcat, (v.booleans for v in variables(m)))



function solve(m::Model)
    p = SymbolicSATProblem(m)

    status, result_dict = solve(p)

    (status == :unsat) && return status, missing

    return status, Dict(v => decode(result_dict, v) for v in m.variables)
end


