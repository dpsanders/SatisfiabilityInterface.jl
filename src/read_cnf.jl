function read_cnf(filename)
    
    lines = filter(line -> !startswith(line, "c"), readlines(filename))

    if !startswith(lines[1], "p cnf")
        error("Incorrect format: First line must be `p cnf`")
    end

    num_vars, num_clauses = parse.(Int, split(lines[1])[3:4])

    clauses = Vector{Int}[]

    line = 2

    for i in 1:num_clauses
        clause = Int[]
        done = false
        
        while true 
            current_literals = parse.(Int, split(lines[line]))
            if current_literals[end] == 0
                done = true 
                pop!(current_literals)
            end

            line += 1

            append!(clause, current_literals)

            done && break 
        end

        push!(clauses, clause)

    end

    return SATProblem(clauses)
end
    

