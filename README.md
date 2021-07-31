# `SatisfiabilityInterface.jl` 

A [Julia](www.julialang.org) package for modelling discrete constraint satisfaction problems and encoding them to Boolean satisfiability (SAT) problems.

## Usage

See this [short video from JuliaCon 2021](https://www.youtube.com/watch?v=F5QuDrTkAow), 
which uses [this Pluto notebook](docs/satisfiability_juliacon_2021.pluto.jl).

See also the `examples` directory for basic usage. 


The resulting SAT problem is solved, by default, using the `CryptoMiniSAT5` SAT solver, which is 
automatically installed.

## Author

Copyright David P. Sanders 2021
