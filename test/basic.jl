using SatisfiabilityInterface
using Symbolics
using Test


@testset "Basic functionality" verbose=true begin
    @testset "Single variable" begin

        @variables x, y, z

        constraints = [
            x ∈ -3:3
            x == 2
        ]

        soln = solve(DiscreteCSP(constraints))
            
        @test soln[1] == :sat 
        @test soln[2] == Dict(x => 2)


        constraints = [
            x ∈ -3:3
            x >= 2
        ]
        
        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => 2), 
                        Dict(x => 3)]


        constraints = [
            x ∈ -3:3
            x > 4
        ]
        
        soln = solve(DiscreteCSP(constraints))
        @test soln[1] == :unsat

    end 

    @testset "Arithmetic" begin

        @variables x, y, z

        constraints = [
            x ∈ 1:3
            y ∈ 1:3
            x + y == 3
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => 2, y => 1), 
                        Dict(x => 1, y => 2)]


        constraints = [
            x ∈ 1:3
            y ∈ 1:3
            z ∈ 1:6
            x + y < 3
            z == (x + y)^2
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => 1, y => 1, z => 4)]

    end 

    @testset "Unary functions" begin

        @variables x, y, z

        constraints = [
            x ∈ -2:2
            abs(x) >= 2
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => +2),
                        Dict(x => -2)]

        constraints = [
            x ∈ 0:1
            y ∈ 0:1
            sign(x - y) == 1
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => 1, y => 0)]
    end

    @testset "Delta indicator" begin

        @variables x, y, z

        constraints = [
            x ∈ -3:3
            y ∈ -3:3
            delta(x-1) + delta(y-2) == 2
            # delta(x-1) is 1 when x==1 and 0 otherwise
            # it allows to reify an equality constraint
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [Dict(x => 1, y => 2)]


        constraints = [
            x ∈ 1:3
            y ∈ 1:3
            delta(x-1) + delta(y-2) >= 1
        ]

        solns = all_solutions(DiscreteCSP(constraints))
        @test solns == [ 
            Dict(y => 2, x => 2),
            Dict(y => 2, x => 3),
            Dict(y => 3, x => 1),
            Dict(y => 2, x => 1),
            Dict(y => 1, x => 1)
        ]
    end

end