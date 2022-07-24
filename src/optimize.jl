# minimize a CSP with respect to a variable `v`
# the variable must be defined (with a domain) in the CSP
function minimize(constraints, v)

    new_constraints = deepcopy(constraints)
    prob = DiscreteCSP(new_constraints)

    sol = solve(prob)

    if sol[1] == :unsat 
        return :unsat 
    end

    value = sol[2][v]   # current value of the variable of interest

    # println("\n")
    # @show value

    while true 

        push!(new_constraints, v < value)
        prob = DiscreteCSP(new_constraints)
        sol = solve(prob)

        if sol[1] == :unsat 
            return value 
        end

        value = sol[2][v]
    end

end

# minimize a CSP with respect to a variable `v`
# the variable must be defined (with a domain) in the CSP
function maximize(constraints, v)

    new_constraints = deepcopy(constraints)
    prob = DiscreteCSP(new_constraints)

    sol = solve(prob)

    if sol[1] == :unsat 
        return :unsat 
    end

    value = sol[2][v]   # current value of the variable of interest

    # println("\n")
    # @show value

    while true 

        push!(new_constraints, v > value)
        prob = DiscreteCSP(new_constraints)
        sol = solve(prob)

        if sol[1] == :unsat 
            return value 
        end

        value = sol[2][v]
    end

end