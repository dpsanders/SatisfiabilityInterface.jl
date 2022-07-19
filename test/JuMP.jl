using JuMP, SatisfiabilityInterface

@testset "JuMP" begin
    model = JuMP.Model(SatisfiabilityInterface.Optimizer)
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
    @test value(x) == 0.0
    @test value(y) == 1.0
    @test value(z) == 0.0
end
