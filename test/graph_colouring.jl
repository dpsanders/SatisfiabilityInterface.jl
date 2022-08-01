using SatisfiabilityInterface
using Symbolics
using Test

different_neighbours(E, c) = [c[i] ≠ c[j] for (i, j) in E]

"Set up a graph colouring problem for a graph 
with vertex set `V`, edge set `E` (a vector of edges (i, j)),
with `k` colours"
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


@testset "Graph colouring" verbose=true begin
        
    @testset begin "Linear graph"
        V = [1, 2, 3]  # vertices
        E = [(1, 2), (2, 3)]  # edges

        prob = graph_colouring_problem(V, E, 2)
        status, results = solve(prob)

        @test status==:sat

        ks = sort(collect(keys(prob.varmap)))
        colours = [results[k] for k in ks]

        @test all(different_neighbours(E, colours))
    end

    @testset "Ring graph" begin

        function ring_graph(n=11)
            V = 1:n
            E = [(i, mod1((i+1), n)) for i in 1:n]
            
            return V, E
        end

        V, E = ring_graph(11)

        prob = graph_colouring_problem(V, E, 2)
        status, results = solve(prob)
        @test status==:unsat

        prob = graph_colouring_problem(V, E, 3)
        status, results = solve(prob)
        @test status==:sat

        ks = sort(collect(keys(prob.varmap)))
        colours = [results[k] for k in ks]
        
        @test all(different_neighbours(E, colours))
    end

end