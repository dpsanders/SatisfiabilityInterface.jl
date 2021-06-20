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


### Subset sum Problem

# https://en.wikipedia.org/wiki/Subset_sum_problem


# Given a set of integers like {−7, −3, −2, 5, 8}, 
# do a subset sum to 0?

s = [-7, -3, -2, 5, 8]
n = length(s)
x = [Num(Variable(:x, i)) for i in 1:n]

constraints = [
    # x .∈ Ref(0:1)
    [x[i] ∈ (0:1) for i in 1:n]
    sum(x[i] * s[i] for i in 1:n)
    sum(x) ≠ 0   # at least one is not 0
    ]

prob = BoundedIntegerCSP(constraints)

all_solutions(prob)



constraint = x + y <= 1
lhs, rhs = process(constraint)


constraint = x + y <= w + z
lhs, rhs = process(constraint)

constraint = x + y + w + z == w
lhs, rhs = process(constraint)





constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
    z ≠ 4
]

prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)

solve(prob3)

solve(prob2)

prob2.additional_vars[1].domain


constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
]


prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)
prob4 = prob3.p

solve(prob3)
solve(prob2)

solns = all_solutions(prob4)
all_solutions(prob3)

### 

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y + x
    x > 1
]



prob = BoundedIntegerCSP(constraints)
all_solutions(prob)




### BeeEncoder example

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

@variables x, y, z, w
b = Num.(Variable.(:b, 1:4))
@variables c, d

constraints = [
    x ∈ 0:5
    y ∈ -4:9
    z ∈ -5:10
    w ∈ 0:10
    b .∈ Ref(0:1)  # boolean
    c ∈ 0:1
    d ∈ 0:1
    x + y == z
    b[1] + b[2] == 1
    b[2] == 1
    c + b[1] == 1   # encode c = ¬b[1]
    d + b[3] == 1

    c + b[2] + d + b[4] == w
    # sum(b) == w

]


prob = ConstraintSatisfactionProblem(constraints)
prob2 = BoundedIntegerCSP(prob)
prob3 = encode(prob2)

status, results = solve(prob3)

decode(prob2, results)

solve(prob2)

prob2.original_vars

all_solutions(prob2)



constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == 2y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
solve(prob)

all_solutions(prob)

prob.additional_vars



constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == -y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
solve(prob)
all_solutions(prob)


constraints = [
    x ∈ 0:5
    y ∈ -4:9
    x == -2y
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
all_solutions(prob)


constraints = [
    x ∈ -5:5
    y ∈ -4:9
    x == -y^2
    # sum(b) == w

]

prob = BoundedIntegerCSP(constraints) 
all_solutions(prob)



constraints = [
    x ∈ -5:5
    y ∈ -4:9
    x - y^2 == 3
    # sum(b) == w

]


prob = BoundedIntegerCSP(constraints) 
all_solutions(prob)


@variables x, y

constraints = [
    x ∈ -5:5
    y ∈ -4:9
    10x + y == 10
    # sum(b) == w
]

prob = BoundedIntegerCSP(constraints) 
all_solutions(prob)

