using SatisfiabilityInterface
using Symbolics



@variables x, y, z, p

# constraints = [
#     x ∈ 1:2
#     y ∈ 2:5
#     z ∈ 3:7
#     p ∈ -100:100
#     z == 2x

#     p == x - y
# ]

constraints = [
    x ∈ -3:-1
    p ∈ -4:4
    p == x - 1
    abs(p) <= 3
]

prob = DiscreteCSP(constraints)

sol = all_solutions(prob)

# minimize v 
function minimize(orig_constraints, v)

    constraints = deepcopy(orig_constraints)
    prob = DiscreteCSP(constraints)

    sol = solve(prob)
    value = sol[2][v]

    # println("\n")
    @show value

    push!(constraints, v < value)
    prob2 = DiscreteCSP(constraints)
    sol2 = solve(prob2)

    value2 = sol2[2][v]

    return sol, sol2

end

minimize(constraints, p)