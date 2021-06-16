module SatisfiabilityInterface

using Symbolics


export DiscreteVariable, ConstraintSatisfactionProblem, BoundedIntegerCSP
export read_cnf, SATProblem
export satisfies

# functions to be extend:
import Base: push!
import CommonSolve: solve


include("discrete_variables.jl")
include("operations.jl")
include("sat_problem.jl")
# include("model.jl")
include("symbolic_problem.jl")
include("solver.jl")
include("encode.jl")

end