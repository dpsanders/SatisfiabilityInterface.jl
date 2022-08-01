
"""
Numeric representation of SAT problem in DIMACS-CNF form

Input: 
- `num_variables` is the number of symbolic Boolean variables
- `clauses` are integer vectors; negative numbers indicate negated variables
"""

"""SAT problem represented numerically in DIMACS-CNF form:
clauses are integer vectors with negative numbers indicating negated literals
"""
mutable struct SATProblem
    num_variables::Int
    clauses::Vector{Vector{Int}} 
end


max_var(clause) = maximum(abs.(clause))

"Constructor which calculates the number of variables automatically"
function SATProblem(clauses::Vector{Vector{Int}})
    num_variables = maximum(max_var.(clauses))

    return SATProblem(num_variables, clauses)
end

Base.push!(p::SATProblem, clause) = push!(p.clauses, clause)

"Ban a clause, i.e. add the negative of the clause"
ban!(p::SATProblem, clause) = push!(p, .-(clause))


function all_solutions(orig_p::SATProblem)

    p = deepcopy(orig_p)

    solns = []
    status = :sat

    while true
        status, results = solve(p)
        status == :unsat && break

        push!(solns, results)
        ban!(p, results)

    end

    return solns
end
