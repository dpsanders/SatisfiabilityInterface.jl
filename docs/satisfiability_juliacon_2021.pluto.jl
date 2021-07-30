### A Pluto.jl notebook ###
# v0.15.0

using Markdown
using InteractiveUtils

# ╔═╡ f4cc5c93-624b-45ca-a4da-fa299c691c8c
begin
	using Pkg
	
	Pkg.activate()
end

# ╔═╡ 23dd09a8-d5d0-11eb-2029-c3cd330fdfa2
begin
	using SatisfiabilityInterface
	
	using Symbolics
	using Symbolics: Sym, Term
	
	using PlutoUI
	
	using LightGraphs, GraphPlot, Colors
	using Compose
end

# ╔═╡ a70a8996-513c-4bbd-aaf8-255d349ee739
using SimpleSATSolver

# ╔═╡ 25d094ff-bfe9-48af-b6b9-f2203ad49e47
using Latexify

# ╔═╡ e2ece52b-efbd-41de-b98e-b9e4e52bf033
using Luxor

# ╔═╡ fbcd65de-d0a4-4914-84f7-5bbbfacd0aa9
emph(s) = HTML("<span style='color:purple'><strong>$s</strong></span>")


# ╔═╡ 533cff90-d873-4c99-8e63-3f0a77811cf6
# TableOfContents()

# ╔═╡ 1a9aad3a-bc69-4a77-bf28-c268a0bc1737
set_default_graphic_size(6*Compose.cm, 6*Compose.cm)  # size for Compose figures


# ╔═╡ 22297817-e948-467c-9a4a-8a1cee20c1e9
html"<button onclick=present()>Present</button>"

# ╔═╡ ec63ded2-3d52-4256-bf8e-638be5133902
md"""
# Solving discrete problems using $(emph("Boolean satisfiability")) with Julia
"""

# ╔═╡ 5c1ac720-70b4-495a-a66c-4ed952fbd137
md"""
### David P. Sanders

#### Facultad de Ciencias $(HTML("<br>")) Universidad Nacional Autónoma de México
#### Department of Mathematics & Julia Lab, MIT
"""

# ╔═╡ f4e269bd-1e67-4bb3-9dc0-fa4c51eae012
md"""
## Outline
"""

# ╔═╡ 67713a33-da7d-495e-911b-051fc34bf638
md"""

- A $(emph("symbolic")) modelling interface for discrete problems
"""

# ╔═╡ 9635873c-7362-4b38-ad9e-1e1eacb49220
md"""
- How to $(emph("encode")) problems as Boolean satisfiability problems
"""

# ╔═╡ fc64bb2e-7c4b-4467-ad68-8d141ae67484
md"""
- How to $(emph("solve")) Boolean satisfiability problems
"""

# ╔═╡ f7598c9b-2673-4b8b-9b2f-b44d648c2b66
HTML("<br>")

# ╔═╡ f42290e3-27f8-4a74-99f0-ed823c5dd16f
md"""
- Related work:

  - `JuliaConstraints` organisation

  - `ConstraintProgrammingExtensions.jl` for JuMP / MOI

"""

# ╔═╡ 7a4f1c53-53cf-44be-9ac0-fdc960bdae51
md"""
## Motivation: Colouring $(emph("graphs"))
"""

# ╔═╡ a1723672-5ce5-4fe8-a808-2cc1da3c8c60
md"""
- A $(emph("graph")) has a set `V` of $(emph("vertices")):
"""

# ╔═╡ d0477e2c-9be5-46de-a85f-bbf94c3f3fe7
V = [1, 2, 3]

# ╔═╡ 13a4d93a-114a-4ccd-aaee-28c80fb0606f
md"""
- Joined by $(emph("edges")) in the set `E`:
"""

# ╔═╡ 90789020-b24c-41a8-847b-e6309babd31f
E = [(1, 2), (2, 3)] 

# ╔═╡ f47c8993-1d2a-4baf-88c7-fa5e605e34b5
gplot(V, E) 

# ╔═╡ e5ea5a80-af37-48ce-91ca-4bc2652c1673
md"""
Graphs rendered using `LightGraphs.jl` and `GraphPlot.jl`
"""

# ╔═╡ 0f305f88-26ca-4acb-9696-ca0bc31ab979
md"""
## Graph $(emph("colouring"))
"""

# ╔═╡ 6a1342de-507b-4008-bedb-5f387f17a850
md"""
- The $(emph("graph colouring")) problem is:
"""

# ╔═╡ e6bd1f4e-e23a-45a0-be82-2f47c1f665cf
md"""

> - Assign a colour to each vertex
"""

# ╔═╡ 729aae42-b4f2-493a-ade8-71a7b790561f
md"""
>   - Such that two vertices joined by an edge have *distinct* colours
"""

# ╔═╡ d61c615e-c751-490c-9889-506c8dee30aa
md"""
## $(emph("Modelling")) the colouring problem
"""

# ╔═╡ c4cc188f-1476-4d39-b4cb-3f5632d23c79
md"""
- We want a mathematical $(emph("model")) for the colouring problem
"""

# ╔═╡ fd63036a-c674-4f30-b8cc-21b67528dd42
md"""
- We use symbolic $(emph("variables")) from `Symbolics.jl`
"""

# ╔═╡ 12628428-1bb1-4f45-8909-88a1d71b8ee7
md"""
- We call $\quad c_i$ = colour of vertex $i$
"""

# ╔═╡ 57e9e379-6ef1-4cc8-ae7b-bd17b4e8e11b
n = length(V)   # number of vertices

# ╔═╡ 4c2c7c62-3b60-48cb-96db-4020885dee1c
@variables c[1:n];    # from Symbolics.jl

# ╔═╡ 8ac35f21-1ed6-4b2e-b019-4ddfd5830851
[c[i] for i in 1:n]

# ╔═╡ 170aaa75-7a8b-4886-90ad-21f417aac55b
md"""
## Domain constraints
"""

# ╔═╡ 759127e1-0703-4fa1-b61f-f4c26c126cc6
md"""
- We need a $(emph("domain")) for each variable
"""

# ╔═╡ b5b9a579-3c53-4724-8f3c-339254fd522d
md"""
- Let's try to colour the graph with 2 colours:
"""

# ╔═╡ c54d16eb-d06a-4dbc-a3e7-c3513da710ee
k = 2

# ╔═╡ e5efb464-042e-48fc-9224-c6505d8e04a3
colours = [:red, :green, :yellow, :blue, :black]

# ╔═╡ 79370a37-d35c-42e5-b6dd-abfd60711fa9
md"""
- We can write domains $(emph("symbolically")):
"""

# ╔═╡ fec874c5-f32d-4988-a6e0-f449d362fc9c
c[1] ∈ colours[1:k]

# ╔═╡ 182e2eac-cf13-4225-a003-cc2c82553ae5
domains = [c[i] ∈ colours[1:k] for i in 1:n]


# ╔═╡ 3fb4ca38-7f53-4251-aa5e-d183b03376af
md"""
## Edge constraints
"""

# ╔═╡ 7ade9ef2-416f-438c-b126-421db2379776
md"""
- If nodes $i$ and $j$ are joined by an edge then they must have distinct colours:
"""

# ╔═╡ d1070d1c-f74d-4bd3-b0ce-862d848fd565
restrictions = [c[i] ≠ c[j] for (i, j) in E]

# ╔═╡ 6e821823-1f30-4b2e-a3e3-4de2a550dc19
md"""
- Let's collect all the constraints together:
"""

# ╔═╡ de3fd8b8-37c2-424e-98be-45824154edd3
constraints = domains ∪ restrictions

# ╔═╡ 0181743f-1a2b-4d44-85b1-77bf08edbf19
md"""
## Constraint satisfaction problem
"""

# ╔═╡ 58ce7a7f-8797-41c1-af47-314157dcd873
md"""
- A $(emph("constraint satisfaction problem")) (CSP) is a collection of variables, domains and constraints
"""

# ╔═╡ 49977007-7b86-426c-bdfa-4fc218bf1e7e
md"""
- We make a `DiscreteCSP` object from `SatisfiabilityInterface.jl` using the constraints:
"""

# ╔═╡ 8d214801-c65d-4d71-bc0c-b05852343428
prob = DiscreteCSP(constraints)

# ╔═╡ c8acfa87-a671-437d-bb9b-b776d014c491
md"""
## Solving the constraint satisfaction problem
"""

# ╔═╡ c600bd16-b655-422d-bb28-7dc124e0ba5a
md"""
- We call `solve` to solve the constraint satisfaction problem:
"""

# ╔═╡ 53a0cc3a-aee5-479e-9a56-9d6563c64c8a
status, results = solve(prob);

# ╔═╡ 760fda23-0027-412d-a3c5-aab300631bc8
results

# ╔═╡ 1df9c28b-54ef-4a1a-adbe-2610861a8559
gplot(V, E, prob, results)

# ╔═╡ d8092ba3-57b9-46aa-ae32-9f66444edb5b
md"""
## Ring graph
"""

# ╔═╡ bb584a01-1051-4b4d-936e-a64e83e58f17
md"""
- Let's make a graph in the form of a ring:
"""

# ╔═╡ 9f6ae168-e89f-4e29-bbf1-057d0dc66c1a
md"""
- Let's try to colour it with 2 colours:
"""

# ╔═╡ b8fe62d5-70e3-4bc7-9d59-9c8ac19ae56f
md"""
	- We see that this is $(emph("unsatisfiable"))!
	"""

# ╔═╡ 4bf219bd-dc77-44e8-91af-9aa67bb26c24
md"""
	
	## Colouring a ring again
	
	- But of course it can be done with *three* colours:
	"""

# ╔═╡ 7b86ec36-6e8d-45a7-bbc7-81c8eb0037e0
md"""
## Colouring a Penrose tiling -- @Cormullion
"""

# ╔═╡ f41caa13-d354-4a42-9bc4-f7ba12f9fffe
PlutoUI.LocalResource("penrose.png")

# ╔═╡ 0110824f-c664-4312-81a4-2cdb967f926b
md"""
## How do we actually $(emph("solve")) these problems?
"""

# ╔═╡ c9db9c18-d1f6-47f4-8e8f-2f158a6eedde
md"""
- We **encode** the problem to a $(emph("boolean satisfiability")) problem (SAT)
"""

# ╔═╡ ef59a7e9-c952-4081-86d0-e5091cf950e5
md"""
- Simple encoding of a variable $x$ with domain 1:$n$ :

  - Use $n$ **Boolean** variables $x_1, \ldots, x_n$

  - Restrict such that **exactly one** of the $x_i$ is true
"""

# ╔═╡ f6769053-14b4-444b-8761-a217ebf3fbf2
encoded = encode(prob)

# ╔═╡ 6a95e734-7f1c-4364-a28c-f7ac7807336a
md"""
## SAT problem in CNF form
"""

# ╔═╡ 5f8ae350-aa2b-4331-9443-af183e355529
md"""
- CNF = $(emph("Conjunctive Normal Form"))

- A conjunction (AND) of clauses

- Each clause is an OR
"""

# ╔═╡ 7442450f-8919-4fe9-ba94-36a27135997d
encoded.p

# ╔═╡ d6d38c75-d38a-4009-acbd-9195370bcbcc
md"""
## SAT solvers
"""

# ╔═╡ a59ffbb7-56a4-4723-a40a-561ed4b995a5
md"""
- The Boolean satisfiability problem is $(emph("NP-complete"))
"""

# ╔═╡ 647b6d87-62ca-43fa-b772-afa8ab9555ac
md"""
- But it can be solved efficiently in many cases, by one of many $(emph("SAT solvers")) that are available
"""

# ╔═╡ e891d669-9431-4ee2-8eb0-d4921c1b2d38
md"""
- Usually written in C or C++
"""

# ╔═╡ f2dbb4d7-5c49-46e7-9535-dc10500e7e61
md"""
- `PicoSAT.jl` wraps the popular `PicoSAT` solver
"""

# ╔═╡ ea0028ed-df33-4f05-adb0-036bc07a8eb2
md"""
- `SatisfiabilityInterface.jl` currently calls out to `cryptominisat5` by default
"""

# ╔═╡ c4e2bb24-462c-450b-a145-c1fea2bd9ee8
md"""
## `SimpleSATSolver.jl`
"""

# ╔═╡ 17f423cf-a241-48f3-a718-51b17ab6a268
md"""
- A very simple SAT solver in $(emph("pure Julia"))
"""

# ╔═╡ bb498e44-559f-414e-ab11-e055037a4b87
md"""
- Implements the $(emph("DPLL algorithm")) (1962)
"""

# ╔═╡ f7061757-93e3-4405-80d3-92f854697e5b
md"""
- Meant to be pedagogical
"""

# ╔═╡ 958cea58-82b1-43b3-975d-aade709c718d
md"""
- But seems to be performant for small systems
"""

# ╔═╡ 03f70163-6712-4e92-9a47-ff246e227813
typeof(encoded.p)

# ╔═╡ ae00c44f-b04b-4233-95cf-9c9a8c6dd799
solve(encoded.p, SimpleSAT())   

# ╔═╡ 1528a881-8501-4122-be89-bf6b75203a60
md"""
## Algorithm for solving boolean satisfiability
"""

# ╔═╡ 44638a74-7b54-4ef2-8a64-c1e8da6cd553
md"""
- Start assigning variables to `true` or `false`
"""

# ╔═╡ fa9d0583-522b-43ea-90b1-70e902b9d55c
md"""
- Check if any constraints are violated and $(emph("backtrack")) (choose the opposite value) if so
	"""

# ╔═╡ 3932867d-74c0-49cc-840e-2d1421a3867a
md"""
- Apply $(emph("unit propagation")):
	
   - If $(x \vee y)$ and $x$ is false then $y$ must be true

"""

# ╔═╡ ddb8ef7d-6e90-4699-a635-5351622f79d6
md"""
## Discrete numerical problems
"""

# ╔═╡ 812ba4be-e5b2-42f0-be4e-7ff643284662
md"""
- We can also solve discrete numerical problems, e.g.: 
"""

# ╔═╡ d1f99f24-d9fb-409d-8ef6-316797a5f88a
vars = @variables x, y, z

# ╔═╡ 955768ef-c550-47ee-b56a-2dc4bc5baad4
numerical_constraints = [
    x ∈ 1:2
    y ∈ 2:5
    z ∈ 3:7
    z == x * y
	x ≠ 1
]

# ╔═╡ 8ed7146d-ca65-4676-b0c9-f97cf67aff32
md"""
## Solving numerical problems
"""

# ╔═╡ 1edf43b4-418d-4615-82a7-00ff7b1ac41c
prob6 = DiscreteCSP(numerical_constraints);


# ╔═╡ 0b0da897-61bb-40cf-a3f9-b30d95c47563
solve(prob6)   # single solution

# ╔═╡ f03160be-b968-4b19-a369-d48cb7dc010a
all_solutions(prob6)

# ╔═╡ 601d3d5d-e613-4c5a-a164-805ccee5f73d
md"""
## Conclusions
"""

# ╔═╡ 2193ce7e-dfde-4bed-a6fb-e4b4831f36fa
md"""
- Encoding to SAT is a $(emph("powerful paradigm")) for solving discrete problems
"""

# ╔═╡ f9580d63-0bdf-4f3b-9dfb-98838f3b666f
md"""
- Our work aims to make this accessible from Julia
"""

# ╔═╡ 6be5dbf5-bee0-4935-a5c7-e5daaad7360d
md"""

- Our packages:

   - `SatisfiabilityInterface.jl` 

   - `SimpleSATSolver.jl`

"""

# ╔═╡ 420da272-eeb9-431c-8bcb-4b8666746655
md"""
# Appendix
"""

# ╔═╡ 97b7b89a-0919-4f81-812a-23d3823b38ba



# ╔═╡ e556a339-a596-49dd-83c3-e0c5c72c7d4d
function convert_to_lightgraphs(V, E)

	g = Graph()
	add_vertices!(g, length(V))
	
	for (i, j) in E
		add_edge!(g, i, j)
	end

	return g
end

# ╔═╡ b0d6ba28-d60d-4aee-a489-79af197a29de
function GraphPlot.gplot(V, E, c, results; nodelabel=V)
	RGB_colours = Dict(col => parse(RGBA, col) for col in colours)
	colour_indices = [results[c[i]] for i in 1:length(c)]

	nodefillc = [RGB_colours[c] for c in colour_indices]
	
	g = convert_to_lightgraphs(V, E)
	
	gplot(g,
		nodelabel=nodelabel,
		nodefillc=nodefillc
	)
	
end

# ╔═╡ 403216ab-a405-43c3-adf6-926be6b063bc
function GraphPlot.gplot(V, E, prob::DiscreteCSP, results; nodelabel=V)
	gplot(V, E, sort(collect(keys(prob.varmap))), results; nodelabel=nodelabel)
end

# ╔═╡ b48b43ba-115c-4b69-9e9c-481e25f12581
function GraphPlot.gplot(V, E; nodelabel=V)
	p = gplot(convert_to_lightgraphs(V, E), nodelabel=nodelabel)
end

# ╔═╡ 80e4d7f7-eb31-480a-beac-abd4bd8b2798

"k is the number of colours"
function graph_colouring_problem(V, E, k=3)

    # colours = [:red, :green, :yellow, :blue, :black][1:k]
    # c = [Num(Variable(:c, i)) for i in 1:length(V)]   # colour variables

    @variables c[1:length(V)]
    
    constraints = 
    [ 
        [c[i] ∈ colours[1:k] for i in 1:length(V)]
        
        [c[i] ≠ c[j] for (i, j) in E]  #  different_colours(E, c)
    ]

    return DiscreteCSP(constraints)
end

# ╔═╡ c1ff01b8-916c-4333-bc34-d0c04debb362
### Fix Latexify output:

# ╔═╡ f796d811-dbaa-4f5f-83a5-5911ac3dae43
begin
	Latexify.latexify(x::Sym)  = Latexify.latexify(Num(x))
	Latexify.latexify(x::Term) = Latexify.latexify(Num(x))
end

# ╔═╡ a16ee047-921f-46bb-bfda-71be201740c3
function ring_graph(n=11)
    V = 1:n
    E = [(i, mod1((i+1), n)) for i in 1:n]
    
    return V, E
end

# ╔═╡ 10f71d92-0575-4940-9c57-27ea52b5fbb1
V2, E2 = ring_graph(3)

# ╔═╡ a79fb891-8ab0-4c19-b801-b7881e5525ca
gplot(V2, E2)

# ╔═╡ 5ee64af1-a53b-4c66-b4b9-0c11b05cae78
prob2 = graph_colouring_problem(V2, E2, 2);

# ╔═╡ a1e31033-998c-4bfc-9d23-8295d5da742d
status2, results2 = solve(prob2)

# ╔═╡ d9b22906-e72a-43dd-81f2-2241e5dca6ee
prob3 = graph_colouring_problem(V2, E2, 3);

# ╔═╡ 26ef3f82-be05-4545-bc1e-cefe96bcddde
status3, results3 = solve(prob3);

# ╔═╡ 9bdaa197-cf4b-45e2-b231-8ec571b3fc95
gplot(V2, E2, prob3, results3)

# ╔═╡ f801d658-0562-4239-9806-e5eccf239fff
## Penrose tiling -- code by Cormullion

# ╔═╡ cd29bbff-a06c-433f-882d-e18b4987114a
struct PenroseTriangle
    red::Bool # not red, more of a flag
    pointA::Point
    pointB::Point
    pointC::Point
end

# ╔═╡ 307e96c3-a270-4b12-a0ac-f865cb20d49a
function subdivide(triangles;
        type=:P3)
    result = []
    for triangle in triangles
        A, B, C = triangle.pointA, triangle.pointB, triangle.pointC
        if triangle.red == true
            if type == :P3
                #  P3 rhombus
                P = A + (B - A) / MathConstants.golden
                push!(result, PenroseTriangle(true, C, P, B))
                push!(result, PenroseTriangle(false, P, C, A))
            else # P2 half kite
                Q = A + (B - A) / MathConstants.golden
                R = B + (C - B) / MathConstants.golden
                push!(result, PenroseTriangle(false, R, Q, B))
                push!(result, PenroseTriangle(true,  Q, A, R))
                push!(result, PenroseTriangle(true,  C, A, R))
            end
        else
            if type == :P3
                # P3 rhombus
                Q = B + (A - B) / MathConstants.golden
                R = B + (C - B) / MathConstants.golden
                push!(result, PenroseTriangle(true, R, Q, A))
                push!(result, PenroseTriangle(false, R, A, C))
                push!(result, PenroseTriangle(false, Q, R, B))
            else # P2 kite/dart
                P = C + (A - C) / MathConstants.golden
                push!(result, PenroseTriangle(false, B, P, A))
                push!(result, PenroseTriangle(true,  P, C, B))
            end
        end
    end
    return result
end

# ╔═╡ 17ae28f4-ba09-42bb-83f0-51f771d0bbc5
function PenroseTiling(centerpos::Point, radius, depth=4;
        type=:P3)
    triangles = PenroseTriangle[]
    A = centerpos
    n = 10 # a circle of triangles 360/10 -> 36°
    for i in 1:n
        phi = (i - 1) * (2π / n)
        C = A + polar(radius, phi)
        phi = (i) * (2π / n)
        B = A + polar(radius, phi)
        if type == :P3
            if i % 2 == 1
                triangle = PenroseTriangle(true, A, C, B)
            else
                triangle = PenroseTriangle(true, A, B, C)
            end
        else # P2
            if i % 2 == 1
                triangle = PenroseTriangle(true, B, A, C)
            else
                triangle = PenroseTriangle(true, C, A, B)
            end
        end
        push!(triangles, triangle)
    end
    for i in 1:depth
        triangles = subdivide(triangles, type=type)
    end
    return triangles
end

# ╔═╡ 759d23f1-360c-4a36-8cf6-0d1f6c6133cd

function incidence_graph(triangles)
    n = length(triangles)
    g = SimpleGraph(n)
    for i in 1:n
        for j in i+1:n
            ti = triangles[i]
            tj = triangles[j]

            points_i = [ti.pointA, ti.pointB, ti.pointC]
            points_j = [tj.pointA, tj.pointB, tj.pointC]

            coincidental = 0
            tol = 1e-2

            for k in 1:3, l in 1:3
                if distance(points_i[k], points_j[l]) < tol
                    coincidental += 1
                end
            end

            if coincidental == 2  # share edge
                add_edge!(g, i, j)
            end
        end
    end

    return g
end


# ╔═╡ 4a0baabf-2d98-4d1a-9906-b05c0654ce86


# ╔═╡ e4281582-9748-4801-972f-2880d6031f1b
tiling = PenroseTiling(O, 1, 4)

# ╔═╡ f32d038d-c126-4fda-bd1c-f33dc039d042
g = incidence_graph(tiling)

# ╔═╡ 0bb71243-3bb9-4ffb-b062-fd8cffa43701
VV = vertices(g)

# ╔═╡ 6f90a7ba-e4cb-4cb1-a60c-f1918642f2b6
EE = [(e.dst, e.src) for e in edges(g)]

# ╔═╡ 0fcbd390-bc8f-4284-b7d3-61428ab6ec82
prob4 = graph_colouring_problem(VV, EE, 4)

# ╔═╡ cf89ab12-e70f-4533-b7e4-52bdc253c18a
@time status4, results4 = solve(prob4)  # 0.05 seconds

# ╔═╡ 38aa8bc1-5b9a-48ae-90e6-5826c86aaff5
unique(values(results4))

# ╔═╡ ff73ed7c-ef11-4876-a345-15f265e753a8


# ╔═╡ 77645c06-1dde-4a29-86bb-5d62f06ee3b0
set_default_graphic_size(20*Compose.cm, 20*Compose.cm)  # size for Compose figures

# ╔═╡ cc04b735-3bff-4f60-a392-2c3d9e6b0220
gplot(VV, EE; nodelabel=nothing)

# ╔═╡ 70405d58-e2e5-4d55-b145-ddaf5a3ed36f
gplot(VV, EE, prob4, results4; nodelabel=nothing)

# ╔═╡ cb819540-f084-45af-bec2-6afb535ab5f9
g.fadjlist[70]

# ╔═╡ bf2a29da-52ed-44f0-b572-38cbb53bd260
results4[c[73]]

# ╔═╡ 31b3bb83-286b-4937-9e86-bed812991013
V5, E5 = ring_graph(31)

# ╔═╡ 7fcbbd88-785f-4c65-96b2-d74239de6e56
prob5 = graph_colouring_problem(V5, E5, 3)

# ╔═╡ c90239b3-d451-4379-adf5-56262ab20b4e
status5, results5 = solve(prob5)

# ╔═╡ 0f1b0462-e0af-4d01-953b-231de11fdf79
gplot(V5, E5, prob5, results5)

# ╔═╡ 8872ee87-e03f-4445-b706-a0b15d86ba07
sort(collect(keys(prob4.varmap)))

# ╔═╡ fa0c842a-b252-4421-90c9-dc713bb1a040
isless(string(c[100]),  string(c[10]))

# ╔═╡ 42429a49-0c05-4b41-96ed-67f58bb762c8
c[100] < c[10]

# ╔═╡ 875f7bd7-a1bd-44f6-a8bb-9a6464cbcc0f
typeof(c[100])

# ╔═╡ eb29d8b9-37b8-4822-a4ec-5a98bd777892
sort(collect(keys(prob4.varmap)))

# ╔═╡ ece5d0ae-8edb-42a0-a467-9effd1253af8
Base.isless(x::Term, y::Term) = isless(x.args[2], y.args[2])

# ╔═╡ 31cdbb1c-044c-4bb0-9fed-ecbb1f8b126e
Base.isless(x::Num, y::Num) = isless(x.val, y.val)

# ╔═╡ 37cb6adb-c6af-47b6-b663-2e89dc11fc0a
isless(c[1], c[100])

# ╔═╡ 1706b53e-0bab-4206-ad88-570039430839
Dump(d.val)

# ╔═╡ Cell order:
# ╠═f4cc5c93-624b-45ca-a4da-fa299c691c8c
# ╠═23dd09a8-d5d0-11eb-2029-c3cd330fdfa2
# ╠═fbcd65de-d0a4-4914-84f7-5bbbfacd0aa9
# ╠═533cff90-d873-4c99-8e63-3f0a77811cf6
# ╠═1a9aad3a-bc69-4a77-bf28-c268a0bc1737
# ╟─22297817-e948-467c-9a4a-8a1cee20c1e9
# ╟─ec63ded2-3d52-4256-bf8e-638be5133902
# ╟─5c1ac720-70b4-495a-a66c-4ed952fbd137
# ╟─f4e269bd-1e67-4bb3-9dc0-fa4c51eae012
# ╟─67713a33-da7d-495e-911b-051fc34bf638
# ╟─9635873c-7362-4b38-ad9e-1e1eacb49220
# ╟─fc64bb2e-7c4b-4467-ad68-8d141ae67484
# ╟─f7598c9b-2673-4b8b-9b2f-b44d648c2b66
# ╟─f42290e3-27f8-4a74-99f0-ed823c5dd16f
# ╟─7a4f1c53-53cf-44be-9ac0-fdc960bdae51
# ╟─a1723672-5ce5-4fe8-a808-2cc1da3c8c60
# ╠═d0477e2c-9be5-46de-a85f-bbf94c3f3fe7
# ╟─13a4d93a-114a-4ccd-aaee-28c80fb0606f
# ╠═90789020-b24c-41a8-847b-e6309babd31f
# ╠═f47c8993-1d2a-4baf-88c7-fa5e605e34b5
# ╟─e5ea5a80-af37-48ce-91ca-4bc2652c1673
# ╟─0f305f88-26ca-4acb-9696-ca0bc31ab979
# ╟─6a1342de-507b-4008-bedb-5f387f17a850
# ╟─e6bd1f4e-e23a-45a0-be82-2f47c1f665cf
# ╟─729aae42-b4f2-493a-ade8-71a7b790561f
# ╟─d61c615e-c751-490c-9889-506c8dee30aa
# ╟─c4cc188f-1476-4d39-b4cb-3f5632d23c79
# ╟─fd63036a-c674-4f30-b8cc-21b67528dd42
# ╟─12628428-1bb1-4f45-8909-88a1d71b8ee7
# ╠═57e9e379-6ef1-4cc8-ae7b-bd17b4e8e11b
# ╠═4c2c7c62-3b60-48cb-96db-4020885dee1c
# ╠═8ac35f21-1ed6-4b2e-b019-4ddfd5830851
# ╟─170aaa75-7a8b-4886-90ad-21f417aac55b
# ╟─759127e1-0703-4fa1-b61f-f4c26c126cc6
# ╟─b5b9a579-3c53-4724-8f3c-339254fd522d
# ╠═c54d16eb-d06a-4dbc-a3e7-c3513da710ee
# ╠═e5efb464-042e-48fc-9224-c6505d8e04a3
# ╟─79370a37-d35c-42e5-b6dd-abfd60711fa9
# ╠═fec874c5-f32d-4988-a6e0-f449d362fc9c
# ╠═182e2eac-cf13-4225-a003-cc2c82553ae5
# ╟─3fb4ca38-7f53-4251-aa5e-d183b03376af
# ╟─7ade9ef2-416f-438c-b126-421db2379776
# ╠═d1070d1c-f74d-4bd3-b0ce-862d848fd565
# ╟─6e821823-1f30-4b2e-a3e3-4de2a550dc19
# ╠═de3fd8b8-37c2-424e-98be-45824154edd3
# ╟─0181743f-1a2b-4d44-85b1-77bf08edbf19
# ╟─58ce7a7f-8797-41c1-af47-314157dcd873
# ╟─49977007-7b86-426c-bdfa-4fc218bf1e7e
# ╠═8d214801-c65d-4d71-bc0c-b05852343428
# ╟─c8acfa87-a671-437d-bb9b-b776d014c491
# ╟─c600bd16-b655-422d-bb28-7dc124e0ba5a
# ╠═53a0cc3a-aee5-479e-9a56-9d6563c64c8a
# ╠═760fda23-0027-412d-a3c5-aab300631bc8
# ╠═1df9c28b-54ef-4a1a-adbe-2610861a8559
# ╟─d8092ba3-57b9-46aa-ae32-9f66444edb5b
# ╟─bb584a01-1051-4b4d-936e-a64e83e58f17
# ╠═10f71d92-0575-4940-9c57-27ea52b5fbb1
# ╠═a79fb891-8ab0-4c19-b801-b7881e5525ca
# ╟─9f6ae168-e89f-4e29-bbf1-057d0dc66c1a
# ╠═5ee64af1-a53b-4c66-b4b9-0c11b05cae78
# ╠═a1e31033-998c-4bfc-9d23-8295d5da742d
# ╟─b8fe62d5-70e3-4bc7-9d59-9c8ac19ae56f
# ╟─4bf219bd-dc77-44e8-91af-9aa67bb26c24
# ╠═d9b22906-e72a-43dd-81f2-2241e5dca6ee
# ╠═26ef3f82-be05-4545-bc1e-cefe96bcddde
# ╠═9bdaa197-cf4b-45e2-b231-8ec571b3fc95
# ╟─7b86ec36-6e8d-45a7-bbc7-81c8eb0037e0
# ╟─f41caa13-d354-4a42-9bc4-f7ba12f9fffe
# ╟─0110824f-c664-4312-81a4-2cdb967f926b
# ╟─c9db9c18-d1f6-47f4-8e8f-2f158a6eedde
# ╟─ef59a7e9-c952-4081-86d0-e5091cf950e5
# ╠═f6769053-14b4-444b-8761-a217ebf3fbf2
# ╟─6a95e734-7f1c-4364-a28c-f7ac7807336a
# ╟─5f8ae350-aa2b-4331-9443-af183e355529
# ╠═7442450f-8919-4fe9-ba94-36a27135997d
# ╟─d6d38c75-d38a-4009-acbd-9195370bcbcc
# ╟─a59ffbb7-56a4-4723-a40a-561ed4b995a5
# ╟─647b6d87-62ca-43fa-b772-afa8ab9555ac
# ╟─e891d669-9431-4ee2-8eb0-d4921c1b2d38
# ╟─f2dbb4d7-5c49-46e7-9535-dc10500e7e61
# ╟─ea0028ed-df33-4f05-adb0-036bc07a8eb2
# ╟─c4e2bb24-462c-450b-a145-c1fea2bd9ee8
# ╟─17f423cf-a241-48f3-a718-51b17ab6a268
# ╟─bb498e44-559f-414e-ab11-e055037a4b87
# ╟─f7061757-93e3-4405-80d3-92f854697e5b
# ╟─958cea58-82b1-43b3-975d-aade709c718d
# ╠═a70a8996-513c-4bbd-aaf8-255d349ee739
# ╠═03f70163-6712-4e92-9a47-ff246e227813
# ╠═ae00c44f-b04b-4233-95cf-9c9a8c6dd799
# ╟─1528a881-8501-4122-be89-bf6b75203a60
# ╟─44638a74-7b54-4ef2-8a64-c1e8da6cd553
# ╟─fa9d0583-522b-43ea-90b1-70e902b9d55c
# ╟─3932867d-74c0-49cc-840e-2d1421a3867a
# ╟─ddb8ef7d-6e90-4699-a635-5351622f79d6
# ╟─812ba4be-e5b2-42f0-be4e-7ff643284662
# ╠═d1f99f24-d9fb-409d-8ef6-316797a5f88a
# ╠═955768ef-c550-47ee-b56a-2dc4bc5baad4
# ╟─8ed7146d-ca65-4676-b0c9-f97cf67aff32
# ╠═1edf43b4-418d-4615-82a7-00ff7b1ac41c
# ╠═0b0da897-61bb-40cf-a3f9-b30d95c47563
# ╠═f03160be-b968-4b19-a369-d48cb7dc010a
# ╟─601d3d5d-e613-4c5a-a164-805ccee5f73d
# ╟─2193ce7e-dfde-4bed-a6fb-e4b4831f36fa
# ╟─f9580d63-0bdf-4f3b-9dfb-98838f3b666f
# ╟─6be5dbf5-bee0-4935-a5c7-e5daaad7360d
# ╟─420da272-eeb9-431c-8bcb-4b8666746655
# ╠═97b7b89a-0919-4f81-812a-23d3823b38ba
# ╠═e556a339-a596-49dd-83c3-e0c5c72c7d4d
# ╠═b0d6ba28-d60d-4aee-a489-79af197a29de
# ╠═403216ab-a405-43c3-adf6-926be6b063bc
# ╠═b48b43ba-115c-4b69-9e9c-481e25f12581
# ╠═80e4d7f7-eb31-480a-beac-abd4bd8b2798
# ╠═c1ff01b8-916c-4333-bc34-d0c04debb362
# ╠═25d094ff-bfe9-48af-b6b9-f2203ad49e47
# ╠═f796d811-dbaa-4f5f-83a5-5911ac3dae43
# ╠═a16ee047-921f-46bb-bfda-71be201740c3
# ╠═f801d658-0562-4239-9806-e5eccf239fff
# ╠═e2ece52b-efbd-41de-b98e-b9e4e52bf033
# ╠═cd29bbff-a06c-433f-882d-e18b4987114a
# ╠═17ae28f4-ba09-42bb-83f0-51f771d0bbc5
# ╠═307e96c3-a270-4b12-a0ac-f865cb20d49a
# ╠═759d23f1-360c-4a36-8cf6-0d1f6c6133cd
# ╠═4a0baabf-2d98-4d1a-9906-b05c0654ce86
# ╠═e4281582-9748-4801-972f-2880d6031f1b
# ╠═f32d038d-c126-4fda-bd1c-f33dc039d042
# ╠═0bb71243-3bb9-4ffb-b062-fd8cffa43701
# ╠═6f90a7ba-e4cb-4cb1-a60c-f1918642f2b6
# ╠═0fcbd390-bc8f-4284-b7d3-61428ab6ec82
# ╠═cf89ab12-e70f-4533-b7e4-52bdc253c18a
# ╠═38aa8bc1-5b9a-48ae-90e6-5826c86aaff5
# ╠═ff73ed7c-ef11-4876-a345-15f265e753a8
# ╠═77645c06-1dde-4a29-86bb-5d62f06ee3b0
# ╠═cc04b735-3bff-4f60-a392-2c3d9e6b0220
# ╠═70405d58-e2e5-4d55-b145-ddaf5a3ed36f
# ╠═cb819540-f084-45af-bec2-6afb535ab5f9
# ╠═bf2a29da-52ed-44f0-b572-38cbb53bd260
# ╠═31b3bb83-286b-4937-9e86-bed812991013
# ╠═7fcbbd88-785f-4c65-96b2-d74239de6e56
# ╠═c90239b3-d451-4379-adf5-56262ab20b4e
# ╠═0f1b0462-e0af-4d01-953b-231de11fdf79
# ╠═8872ee87-e03f-4445-b706-a0b15d86ba07
# ╠═fa0c842a-b252-4421-90c9-dc713bb1a040
# ╠═42429a49-0c05-4b41-96ed-67f58bb762c8
# ╠═875f7bd7-a1bd-44f6-a8bb-9a6464cbcc0f
# ╠═eb29d8b9-37b8-4822-a4ec-5a98bd777892
# ╠═ece5d0ae-8edb-42a0-a467-9effd1253af8
# ╠═31cdbb1c-044c-4bb0-9fed-ecbb1f8b126e
# ╠═37cb6adb-c6af-47b6-b663-2e89dc11fc0a
# ╠═1706b53e-0bab-4206-ad88-570039430839
