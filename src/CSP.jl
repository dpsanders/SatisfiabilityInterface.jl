


Base.isless(x::Sym, y::Sym) = isless(x.name, y.name)
Base.isless(x::Term, y::Term) = isless(string(x), string(y))
Base.isless(x::Term, y::Sym) = isless(string(x), string(y))
Base.isless(x::Sym, y::Term) = isless(string(x), string(y))

struct ConstraintSatisfactionProblem 
    original_vars 
    additional_vars   # from binarizing
    domains
    constraints 
end

function ConstraintSatisfactionProblem(constraints)

    domains, new_constraints, additional_vars = parse_constraints(constraints)
    # # @show keys(domains)
    vars = sort(identity.(keys(domains)))
    additional_vars = sort(identity.(additional_vars))

    return ConstraintSatisfactionProblem(vars, additional_vars, domains, new_constraints)
end


struct DiscreteCSP
    original_vars
    additional_vars
    constraints
    varmap   # maps symbolic variables to the corresponding DiscreteVariable
end


DiscreteCSP(constraints) = DiscreteCSP(ConstraintSatisfactionProblem(constraints))

function DiscreteCSP(prob::ConstraintSatisfactionProblem)
    variables = []
    varmap = Dict()

    new_constraints = []

    for (var, domain) in prob.domains
        variable = DiscreteVariable(var, domain)
        push!(variables, variable)
        push!(varmap, var => variable)
    end

    for constraint in prob.constraints 
        constraint = value(constraint)

        # # @show constraint

        if constraint isa Assignment 

            lhs = constraint.lhs

            # # @show lhs 

            op, new_args = parse_expression(varmap, constraint.rhs)   # makes a BinaryNode

            # @show op, new_args 

            if length(new_args) == 2
                variable = BinaryNode(op, new_args[1], new_args[2], name=lhs)
            elseif length(new_args) == 1
                variable = UnaryNode(op, new_args[1], name=lhs)

            else
                error("Can't handle $constraint")
            end
            
            push!(variables, variable)
            push!(varmap, lhs => variable)

        else
            # # @show constraint
            push!(new_constraints, parse_relation(varmap, constraint))
        end
    end

    original_vars = [varmap[var] for var in prob.original_vars]
    additional_vars = [varmap[var] for var in prob.additional_vars]
   
    return DiscreteCSP(original_vars, additional_vars, new_constraints, varmap)
end




function encode(prob::DiscreteCSP)
    all_variables = []
    all_clauses = []

    variables = Any[prob.original_vars; prob.additional_vars]
    

    domains = Dict(name(v) => domain(v) for v in variables)

    for var in variables
        append!(all_variables, booleans(var))
        append!(all_clauses, clauses(var))
    end

    # # @show prob.constraints

    for constraint in prob.constraints 
        # # @show constraint
        append!(all_clauses, encode(constraint))
    end

    # @show identity.(all_variables)
    # @show identity.(all_clauses)

    return SymbolicSATProblem(identity.(all_variables), identity.(all_clauses))
    # identity.(...) reduces to the correct type 
end


function solve(prob::DiscreteCSP)
    symbolic_sat_problem = encode(prob)

    status, result_dict = solve(symbolic_sat_problem)

    (status == :unsat) && return status, missing

    # variables = Any[prob.original_vars; prob.additional_vars]
    variables = prob.original_vars

    return status, decode(prob, result_dict)
end

decode(prob::DiscreteCSP, result_dict) = Dict(v.name => decode(result_dict, v) for v in prob.original_vars)
    


function all_solutions(prob::DiscreteCSP)
    sat_problem = encode(prob)
    # variables = Any[prob.original_vars; prob.additional_vars]
    variables = prob.original_vars

    prob2 = encode(prob)
    prob3 = prob2.p   # SATProblem

    sat_solutions = all_solutions(prob3)

    if isempty(sat_solutions)
        return sat_solutions 
    end

    solutions = Dict{Num, Int}[]

    for solution in sat_solutions
        push!(solutions, decode(prob, decode(prob2, solution)))
    end

    return solutions

end
