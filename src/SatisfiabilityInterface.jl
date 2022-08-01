module SatisfiabilityInterface

using Symbolics
using Symbolics: variable, Sym
using Symbolics: Assignment, get_variables, operation, arguments, value, istree
using CryptoMiniSat_jll
using ReversePropagation

export DiscreteVariable, ConstraintSatisfactionProblem, DiscreteCSP, SymbolicSATProblem, SATProblem
export read_cnf, SATProblem
export satisfies
export encode, solve, all_solutions
export minimize, maximize
export delta

# functions to be extend:
import Base: push!
import CommonSolve: solve

include("symbolics_interface.jl")
include("discrete_variables.jl")
include("nodes.jl")
include("sat_problem.jl")
include("symbolic_problem.jl")
include("MOI_wrapper.jl")
include("read_cnf.jl")
include("solver.jl")
include("parsing.jl")

include("relations.jl")
include("CSP.jl")
# include("optimize.jl")

end
