module SatisfiabilityInterface

using Symbolics
using Symbolics: Variable, Sym
using Symbolics: Assignment, get_variables, operation, arguments, value, istree


export DiscreteVariable, ConstraintSatisfactionProblem, BoundedIntegerCSP, SymbolicSATProblem, SATProblem
export read_cnf, SATProblem
export satisfies
export encode, solve

# functions to be extend:
import Base: push!
import CommonSolve: solve

include("symbolics_interface.jl")
include("discrete_variables.jl")
include("operations.jl")
include("sat_problem.jl")
include("symbolic_problem.jl")
include("solver.jl")
include("encode.jl")

end