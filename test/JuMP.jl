using JuMP, SatisfiabilityInterface
import Kissat_jll

@testset "JuMP" begin
    solver = SatisfiabilityInterface.ExternalSATSolver(
        Kissat_jll.kissat,
        "",
        Dict(10 => :sat, 15 => :unknown, 20 => :unsat),
    )
    model = JuMP.Model(() -> SatisfiabilityInterface.Optimizer(solver))
    @variable(model, x, Bin)
    @variable(model, y, Bin)
    @variable(model, z, Bin)
    @constraint(model, [x, y, z] in SatisfiabilityInterface.CNF([true, true, true]))
    @constraint(model, [x, y, z] in SatisfiabilityInterface.CNF([false, true, true]))
    @constraint(model, [x, y]    in SatisfiabilityInterface.CNF([false, false]))
    @constraint(model, [y, z]    in SatisfiabilityInterface.CNF([false, false]))
    @constraint(model, [x, z]    in SatisfiabilityInterface.CNF([true, false]))
    optimize!(model)
    @test raw_status(model) == "sat"
    @test termination_status(model) == MOI.OPTIMAL
    @test primal_status(model) == MOI.FEASIBLE_POINT
    s = round.(Int, value.([x, y, z])) .== 1
    @test s[1] | s[2] | s[3]
    @test !s[1] | s[2] | s[3]
    @test !s[1] | !s[2]
    @test !s[2] | !s[3]
    @test s[1] | !s[3]
end
