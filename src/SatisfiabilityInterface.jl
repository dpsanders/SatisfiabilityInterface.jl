module SatisfiabilityInterface

using ModelingToolkit

export BoundedInteger, Model, solve, make_vector, read_cnf

import Base: push!

include("modeling_toolkit_interface.jl")
include("bounded_integer.jl")
include("constraints.jl")
include("model.jl")
include("sat_problem.jl")
include("solver.jl")
include("symbolic_problem.jl")
include("MOI_wrapper.jl")
include("read_cnf.jl")

end
