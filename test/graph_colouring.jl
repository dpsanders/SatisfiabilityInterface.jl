

different_neighbours(E, c) = [c[i] ≠ c[j] for (i, j) in E]

function graph_colouring_problem(V, E, k=3)

    c = make_vector(:c, BoundedInteger{k}, length(V))  # colour variables
    
    m = Model(c, different_neighbours(E, c))

    return m
end


@testset "Graph colouring" begin
            
    V = [1, 2, 3]  # vertices
    E = [(1, 2), (2, 3)]  # edges

    m = graph_colouring_problem(V, E, 2)
    status, results = solve(m)

    @test status==:sat

    colours = [results[k] for k in SatisfiabilityInterface.variables(m)]

    @test all(different_neighbours(E, colours))
end

@testset "Ring graph" begin

    function ring_graph(n=11)
        V = 1:n
        E = [(i, mod1((i+1), n)) for i in 1:n]
        
        return V, E
    end

    V, E = ring_graph(11)

    m = graph_colouring_problem(V, E, 2)
    status, results = solve(m)
    @test status==:unsat

    m = graph_colouring_problem(V, E, 3)
    status, results = solve(m)
    @test status==:sat

    colours = [results[k] for k in SatisfiabilityInterface.variables(m)]

    @test all(different_neighbours(E, colours))

end