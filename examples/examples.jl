using Symbolics
using SatisfiabilityInterface


vars = @variables x, y, z, w

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
]

prob = DiscreteCSP(constraints)

solve(prob)

all_solutions(prob)


###


vars = @variables x, y, z, w

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    w ∈ 4:6
    z == x + y
    w == z + x
]

prob = DiscreteCSP(constraints)
solve(prob)
all_solutions(prob)


###

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == 2x
]

all_solutions(DiscreteCSP(constraints))

###

vars = @variables x, y, z 

# constraints = [
#     x ∈ 1:4
#     y ∈ 2:5
#     z == x + y
#     z ≤ 4
# ]



### Subset sum Problem

# https://en.wikipedia.org/wiki/Subset_sum_problem


# Given a set of integers like {−7, −3, −2, 5, 8}, 
# do a subset sum to 0?

s = [-7, -3, -2, 5, 8]
n = length(s)
x = [Symbolics.variable(:x, i)) for i in 1:n]
# @variables x[1:n]

constraints = [
    [x[i] ∈ (0:1) for i in 1:n]
    sum(x[i] * s[i] for i in 1:n) == 0
    sum(x) ≠ 0   # at least one is not 0
    ]

prob = DiscreteCSP(constraints)

all_solutions(prob)


#####

@variables x, y, z

constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == 2x
]



prob = DiscreteCSP(constraints)
all_solutions(prob)

## Example from https://github.com/newptcai/BeeEncoder.jl

function make_vector(name::Symbol, range)
    return variable.(name, range)
end

@variables x, y, z, w
b = make_vector(:b, 1:4)
# @variables b[1:4]


¬(x::Num) = 1 - x   # assumes a Boolean variable


constraints = [
    x ∈ 0:5
    y ∈ -4:9
    z ∈ -5:10
    w ∈ 0:10

    [bb ∈ 0:1 for bb ∈ b]
    
    x + y == z
    
    b[1] == ¬b[2]
    b[2] == 1

    ¬b[1] + b[2] + ¬b[3] + b[4] == w
]

prob = DiscreteCSP(constraints)
solve(prob)

# @time length(all_solutions(prob))   # 1184 solutions in 38 seconds



### 

constraints = [
    x ∈ -5:5
    y ∈ -4:9
    x - y^2 == 3
    # sum(b) == w

]


prob = DiscreteCSP(constraints) 
all_solutions(prob)

### 

@variables x, y

constraints = [
    x ∈ -5:5
    y ∈ -4:9
    10x + y == 9
    # sum(b) == w
]

prob = DiscreteCSP(constraints) 
all_solutions(prob)


