
using Revise, SatisfiabilityInterface, Symbolics

"Constraints representing different colours for each edge of a graph"
different_colours(E, c) = [c[i] ≠ c[j] for (i, j) in E]




"k is the number of colours"
function graph_colouring_problem(V, E, k=3)

    colours = [:red, :green, :yellow, :blue, :black][1:k]
    # c = [Num(Variable(:c, i)) for i in 1:length(V)]   # colour variables

    @variables c[1:length(V)]
    
    constraints = 
    [ 
        [c[i] ∈ colours for i in 1:length(V)]
        
        [c[i] ≠ c[j] for (i, j) in E]  #  different_colours(E, c)
    ]

    return DiscreteCSP(constraints)
end


# cs = [Num(Variable(:c, i)) for i in 1:length(V)]   # colour variables


# constraints = [ 
#     [c ∈ colours for c in cs]
#     different_colours(E, cs)
# ]



V = [1, 2, 3]  # vertices
E = [(1, 2), (2, 3)]  # edges

prob = graph_colouring_problem(V, E, 2)
status, results = solve(prob)

# final_colours = [second(results[k]) for k in prob.original_vars]

# # check that it satisfies the constraint:
# all(different_neighbours(E, final_colours))


## Ring graph 

function ring_graph(n=11)
    V = 1:n
    E = [(i, mod1((i+1), n)) for i in 1:n]
    
    return V, E
end

V, E = ring_graph(11)

prob = graph_colouring_problem(V, E, 2)
status, results = solve(prob)


prob = graph_colouring_problem(V, E, 3)
status, results = solve(prob)
status==:sat

# final_colours = [results[k] for k in prob.variables]
# all(different_neighbours(E, final_colours))




k = 3
colours = [:red, :green, :yellow, :blue, :black][1:k]

c = [Num(Variable(:c, i)) for i in 1:length(V)]   # colour variables


constraints = 
    [ 
        [c[i] ∈ colours for i in 1:length(V)]
        
        [c[i] ≠ c[j] for (i, j) in E]  #  different_colours(E, c)
    ]

constraints

prob = ConstraintSatisfactionProblem(constraints)
prob2 = DiscreteCSP(prob)

solve(prob2)


k = 3









######### Count number of each colour 
# V = [1, 2, 3]; E = [(1, 2), (2, 3)];
# V = [1, 2, 3]; E = [(1, 2), (2, 3), (1, 3)];

# k = 2; colours = [:red, :green, :yellow, :blue, :black][1:k]

# ring graph:
m = 11
V = 1:m
E = [(i, mod1((i+1), m)) for i in 1:m]


colours = 1:5


n = [Symbolics.variable(:n, i) for i in 1:length(colours)]
c = [Symbolics.variable(:c, i) for i in 1:length(V)]

@variables num_colours

constraints = [
    [c[i] ∈ colours for i in 1:length(V)]
    [n[i] ∈ 0:20 for i in 1:length(colours)]

    num_colours ∈ 0:10

    [c[i] ≠ c[j] for (i, j) in E]  #  different_colours(E, c)

    [n[j] == sum(delta(c[i] - j) for i in 1:length(V)) for j in 1:length(colours)]

    num_colours == sum(sign(abs(n[j])) for j in 1:length(colours))
    # sign(abs(n)) gives 0 if n == 0 and 1 if n > 0
]

solve(DiscreteCSP(constraints))

minimize(constraints, num_colours)