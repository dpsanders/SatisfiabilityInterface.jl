

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


function solve(p::SATProblem; solver=cryptominisat)
    s = dimacs_output(p)

    input = "_input.cnf"
    write(input, s)

    # return @time call_solver(solver, input=input)
    return call_solver(solver, input=input)
end

abstract type AbstractSATSolver end

"""
Object representing an external SAT solver binary (executable).

- `name`: Name of the executable
- `options`: Options to pass in
- `status`: Dictionary containing exit codes and their interpretation
"""
struct ExternalSATSolver <: AbstractSATSolver
    exe
    options::String
    status::Dict{Int, Symbol}
end

const cryptominisat =
    ExternalSATSolver(CryptoMiniSat_jll.cryptominisat5, "",
                Dict(10 => :sat,
                     15 => :unknown,
                     20 => :unsat) )

"""
Call a solver executable (binary) that takes `.cnf` input.
The solver's standard output is captured to a file.
"""
function call_solver(solver; input="_input.cnf", output="_out.txt")
    # run the solver:
    solver.exe() do exe
        cmd = `$(exe) $input`

        pipe = pipeline(cmd, stdout=output)
        out = run(pipe, wait=false);
        wait(out)

        status = solver.status[out.exitcode]

        status ∈ (:unsat, :unknown) && return status, Int[]

        output = filter(line -> !startswith(line, "c"), readlines(output))

        # TODO: check for correct initial letter

        results = reduce(vcat, parse_line.(output[2:end]))
        pop!(results)  # remove final 0
        return status, results
    end
end



"""
Check that the clause is satisfied by the assignments
in `results`
"""
function satisfies(clause::Vector{Int}, results)
    return any(x -> results[abs(x)] == x, clause)
end

"""
Check that all clases in `p` are satisfied by the
assignments in `results`
"""
function satisfies(p, results)
    return all(satisfies.(p.clauses, Ref(results)))
end
