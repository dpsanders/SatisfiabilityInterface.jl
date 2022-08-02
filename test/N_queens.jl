using SatisfiabilityInterface
using Symbolics
using Symbolics: variable
using Test

q = [variable(:q, i) for i in 1:8]

function N_queens(N)

    constraints = [
        [q[i] ∈ 1:N for i in 1:N]
        [q[i] != q[j] for i in 1:N for j in i+1:N]
        [abs(q[i] - q[j]) != abs(i - j) for i in 1:N for j in i+1:N]
    ]

    return DiscreteCSP(constraints)
end

@testset "N queens" begin 
    
    prob = N_queens(4)
    solns = all_solutions(prob)

    (q₁, q₂, q₃, q₄) = q[1:4]

    @test solns == [
        Dict(q₁ => 2, q₂ => 4, q₃ => 1, q₄ => 3),
        Dict(q₁ => 3, q₂ => 1, q₃ => 4, q₄ => 2)
    ]


    prob = N_queens(8)
    solns = all_solutions(prob)

    @test length(solns) == 92
end