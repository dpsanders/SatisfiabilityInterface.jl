

output_clause(v) = join(v, " ") * " 0"

"""
Create string for DIMACS output.
Each clause is terminated by 0.

TODO: If clauses are too long they should be split up into separate lines.
"""
function dimacs_output(p::SATProblem)

    header = """
    c DIMACS created by sat.jl
    p cnf $(p.num_variables) $(length(p.clauses))
    """

    body = join(output_clause.(p.clauses), "\n")

    return header * body * "\n"
end

parse_line(s) = parse.(Int, split(s)[2:end])

# exit codes from CryptoMiniSat:
const SAT_status = Dict(10 => :sat, 
                         15 => :unknown,
                         20 => :unsat)

"Use SAT solver to solve"
function call_solver(; solver="cryptominisat5", input="_input.cnf", output="_out.txt")

    # if solver == "cryptominisat5" && options == ""
    #     options = "--verb=0"  # remove verbose output
    # end

    # run the solver:
    cmd = `$solver $input`
    # @show cmd
    pipe = pipeline(cmd, stdout=output)
    out = run(pipe, wait=false);
    wait(out)

    status = SAT_status[out.exitcode]

    status ∈ (:unsat, :unknown) && return status, Int[]

    output = filter(line -> !startswith(line, "c"), readlines(output))

    # TODO: check for correct initial letter
    
    results = reduce(vcat, parse_line.(output[2:end]))
    pop!(results)  # remove final 0

    return status, results
end


function solve(p::SATProblem)
    s = dimacs_output(p)

    input = "_input.cnf"
    write(input, s)

    return @time call_solver(input=input)
end
