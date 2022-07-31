import MathOptInterface

const MOI = MathOptInterface

mutable struct Optimizer{T} <: MOI.AbstractOptimizer
    problem::SATProblem
    status::Symbol
    results::Vector{Int}
    is_zeroone::Vector{Bool}
end

const NOT_CALLED = :notcalled

function Optimizer{T}() where {T}
    return Optimizer{T}(SATProblem(0, Vector{Int}[]), NOT_CALLED, Int[], Bool[])
end

# JuMP will expects `VariablePrimal` to return `Float64`
Optimizer() = Optimizer{Float64}()

function MOI.empty!(model::Optimizer)
    model.problem.num_variables = 0
    empty!(model.problem.clauses)
    model.status = NOT_CALLED
    empty!(model.results)
    return
end

function MOI.is_empty(model::Optimizer)
    return iszero(model.problem.num_variables) && isempty(model.problem.clauses)
end


MOI.get(::Optimizer, ::MOI.SolverName) = "SATInterface"

function MOI.add_variable(model::Optimizer)
    model.problem.num_variables += 1
    push!(model.is_zeroone, false)
    return MOI.VariableIndex(model.problem.num_variables)
end

MOI.supports_incremental_interface(::Optimizer) = true

function MOI.copy_to(model::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(model, src)
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{MOI.ZeroOne},
)
    return true
end

function MOI.add_constraint(
    model::Optimizer,
    x::MOI.VariableIndex,
    ::MOI.ZeroOne,
)
    model.is_zeroone[x.value] = true
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(x.value)
end

struct CNF <: MOI.AbstractVectorSet
    not::Vector{Bool}
end

MOI.dimension(set::CNF) = length(set.not)

Base.copy(set::CNF) = CNF(Base.copy(set.not))

_not(id::Int, not::Bool) = not ? -id : id

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CNF},
)
    return true
end

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorOfVariables,
    set::CNF,
)
    clause = Int[
        _not(func.variables[i].value, set.not[i]) for i in eachindex(set.not)
    ]
    push!(model.problem, clause)
    index = length(model.problem.clauses)
    return MOI.ConstraintIndex{typeof(func),typeof(set)}(index)
end
function MOI.optimize!(model::Optimizer)
    @assert all(model.is_zeroone)
    model.status, model.results = solve(model.problem)
    return
end

const TERM = Dict(
    NOT_CALLED => MOI.OPTIMIZE_NOT_CALLED,
    :sat => MOI.OPTIMAL,
    :unsat => MOI.INFEASIBLE,
    :unknown => MOI.TIME_LIMIT,
)

MOI.get(model::Optimizer, ::MOI.RawStatusString) = string(model.status)

function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.status == NOT_CALLED
        return MOI.OPTIMIZE_NOT_CALLED
    elseif model.status == :sat
        return MOI.OPTIMAL
    elseif model.status == :unsat
        return MOI.INFEASIBLE
    elseif model.status == :unknown
        return MOI.OTHER_ERROR
    end
end

MOI.get(model::Optimizer, ::MOI.ResultCount) = model.status == :sat ? 1 : 0

function MOI.get(model::Optimizer, attr::MOI.PrimalStatus)
    if 1 <= attr.result_index <= MOI.get(model, MOI.ResultCount())
        return MOI.FEASIBLE_POINT
    end
    return MOI.NO_SOLUTION
end

MOI.get(::Optimizer, ::MOI.DualStatus) = MOI.NO_SOLUTION

function MOI.get(model::Optimizer, ::MOI.VariablePrimal, vi::MOI.VariableIndex)
    return model.results[vi.value] > 0
end
