using Symbolics
using SatisfiabilityInterface


vars = @variables x, y, z 

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    w ∈ 4:4
    z == x * y
    z ≠ w
]

x ∈ 1:2

prob = BoundedIntegerCSP(vars, constraints)

prob.variables[3].booleans

prob2 = SatisfiabilityInterface.encode(prob)

prob2.p

solve(prob)





vars = @variables x, y, z, w

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    w ∈ 4:6
    z == x + y
    w == z + x
]

solve(BoundedIntegerCSP(vars, constraints))

# vars = @variables x, y, z, w

# constraints = [
#     x ∈ 1:2
#     y ∈ 2:5
#     z ∈ 3:7
#     z ==  2x
# ]

solve(BoundedIntegerCSP(vars, constraints))


### Problem from BeeEncoder

#=
@beeint x  0 5
@beeint y -4 9
@beeint z -5 10

@constrain x + y == z

@beeint w 0 10

xl = @beebool x[1:4]

@constrain xl[1] == -xl[2]
@constrain xl[2] == true

@constrain sum([-xl[1], xl[2], -xl[3], xl[4]]) == w
=#



@variables x, y, z, w, xl[1:4]

vars = [x; y; z; w; xl]
constraints = [z == x + y
                xl[1] + xl[2] ∈ 0:0
                xl[2] ∈ 1:1
                # express not etc.
]
                



@variables x, y, z
domains = Dict(value(x) => -Inf..Inf, value(y) => -Inf..Inf, value(z) => -Inf..Inf)

parse_constraint!(domains, x ∈ 1:2)
parse_constraint!(domains, y ∈ 2:5)
domains[x]

parse_constraint!(domains, z == x + y)
parse_constraint!(domains, z ≤ 4)
parse_constraint!(domains, z ≤ 3)

domain(x::Sym) = domains[x]



colours = [:red, :yellow, :blue]

x = DiscreteVariable(:x, colours)
y = DiscreteVariable(:y, 2:4)

clauses(x)
clauses(y)

domain(x)
# vars(x)


vars = @variables x, y, z 

constraints = [
    x ∈ 1:4
    y ∈ 2:5
    z == x + y
    z ≤ 4
]

domains, binary_constraints = parse_constraints(vars, constraints)


## Graph colouring

constraints = [c[i] ≠ c[j] for i in 1:length(c) for j in i+1:length(c)]

@variables x, y, z, w

z = x + y + w

u = x + y
z = u + w 


vars = @variables nsw, v, t

vars

colours = [:red, :green, :blue]

constraints = [
    nsw ∈ colours
    v ∈ colours
    t ∈ colours
    [vars[i] ≠ vars[j] for i in 1:3 for j in i+1:3]

]

prob = BoundedIntegerCSP(vars, constraints)

solve(prob)