
using SatisfiabilityInterface, Symbolics

"Constraints representing different colours for each edge of a graph"
different_colours(E, c) = [c[i] ≠ c[j] for (i, j) in E]

"k is the number of colours"
function graph_colouring_problem(V, E, k=3)

    colours = 1:k
    c = [Variable(:c, i) for i in 1:length(V)]   # colour variables
    
    constraints = [ c .∈ Ref(colours)
                    different_colours(E, c)
    ]

    return BoundedIntegerCSP(c, constraints)
end

num_colours = k
colours = 1:k 

cs = [Variable(:c, i) for i in 1:length(V)]   # colour variables


constraints = [ 
    [c ∈ colours for c in cs]
    different_colours(E, cs)
]

V = [1, 2, 3]  # vertices
E = [(1, 2), (2, 3)]  # edges

prob = graph_colouring_problem(V, E, 2)
status, results = solve(prob)

final_colours = [results[k] for k in prob.variables]

# check that it satisfies the constraint:
all(different_neighbours(E, final_colours))


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

final_colours = [results[k] for k in prob.variables]
all(different_neighbours(E, final_colours))
