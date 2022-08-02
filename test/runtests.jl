using SatisfiabilityInterface
using Test

@testset "SatisfiabilityInterface.jl" verbose=true begin
    include("basic.jl")
    include("graph_colouring.jl")
    include("sudoku.jl")
    include("N_queens.jl")
    
    include("MOI_wrapper.jl")
    include("JuMP.jl")

end
