# include("../src/LightGraphs.jl")
# pd = pwd()
using LightGraphs
pd = joinpath(Pkg.dir(), string(module_name(LightGraphs)))

# This file generated the Markdown documentation files.

# The @file macro generates the documentation for a particular file
# where the {{method1, methods2}} includes the documentation for each method
# via the `buildwriter` function.

# Currently this prints the methodtable followed by the docstring.

macro file(args...) buildfile(args...) end

buildfile(t, s::AbstractString) = buildfile(t, Expr(:string, s))

buildfile(target, source::Expr) = quote
    open(joinpath(dirname(@__FILE__), $(esc(target))), "w") do file
        println(" - '$($(esc(target)))'")
        println(file, "<!-- AUTOGENERATED. See 'doc/build.jl' for source. -->")
        $(Expr(:block, [buildwriter(arg) for arg in source.args]...))
    end
end

buildwriter(ex::Expr) = :(print(file, $(esc(ex))))

buildwriter(t::AbstractString) = Expr(:block,
    [buildwriter(p, iseven(n)) for (n, p) in enumerate(split(t, r"^{{|\n{{|}}\s*(\n|$)"))]...
)


buildwriter(part, isdef) = isdef ?
    begin
        parts = Expr(:vect, [:(($(parse(p))), @doc($(parse(p)))) for p in split(part, r"\s*,\s*")]...)
        quote
            for (f, docstring) in $(esc(parts))
                if isa(f, Function)
                    docs = getlgdoc(docstring)
                    printsignature = true
                    if isa(docs[1][1], Markdown.Code)
                        c = docs[1][1].code
                        s = split(string(f),".")
                        if ((length(s) == 1  &&  startswith(c, s[1]))
                           || (length(s) > 1 && s[1] == "LightGraphs" && startswith(c, s[2])))
                            printsignature = false
                        end
                    end
                    printsignature && md_methodtable(file, f)
                    writemime(file, "text/plain", docs[1])
                    if length(docs) > 1
                        for d in docs[2:end]
                            println(file)
                            writemime(file, "text/plain", d)
                        end
                    end
                else
                    writemime(file, "text/plain", docstring)
                end
                println(file)
            end
        end
    end :
    :(print(file, $(esc(part))))

getlgdoc(docstring) = docstring.content[find(c->c.meta[:module] == LightGraphs, docstring.content)]

function md_methodtable(io, f)
    println(io, "### ", first(methods(f)).func.code.name)
    println(io, "```")
    for m in methods(f)
        md_method(io, m)
    end
    println(io, "```")
end
function md_method(io, m)
    # We only print methods with are defined in the parent (project) directory
    if !(startswith(string(m.func.code.file), pd))
        return
    end
    print(io, m.func.code.name)
    tv, decls, file, line = Base.arg_decl_parts(m)
    if !isempty(tv)
        Base.show_delim_array(io, tv, '{', ',', '}', false)
    end
    print(io, "(")
    print_joined(io, [isempty(d[2]) ? "$(d[1])" : "$(d[1])::$(d[2])" for d in decls],
                 ", ", ", ")
    print(io, ")")
    println(io)
end

@file "about.md" "{{LightGraphs}}"
@file "basicmeasures.md" """
The following basic measures have been implemented for `Graph` and `DiGraph`
types:

## Vertices and Edges

{{vertices, edges, is_directed, nv, ne, has_edge, has_vertex, in_edges, out_edges, src, dst, reverse}}

## Neighbors and Degree

{{degree, indegree, outdegree, Δ, δ, Δout, δout, δin, Δin, degree_histogram, density, neighbors, in_neighbors, all_neighbors, common_neighbors}}
"""

@file "centrality.md" """
# Centrality Measures

[Centrality measures](https://en.wikipedia.org/wiki/Centrality) describe the
importance of a vertex to the rest of the graph using some set of criteria.
Centrality measures implemented in *LightGraphs.jl* include the following:

## Degree Centrality

{{degree_centrality, indegree_centrality, outdegree_centrality}}

### Closeness Centrality

{{closeness_centrality}}

## Betweenness Centrality

{{betweenness_centrality}}

## Katz Centrality

{{katz_centrality}}

## PageRank

{{pagerank}}
"""

@file "distance.md" """
*LightGraphs.jl* includes the following distance measurements:

{{eccentricity, radius, diameter, center, periphery}}
"""

@file "cliques.md" """
## Cliques
*LightGraphs.jl* implements maximal clique discovery using

{{maximal_cliques}}
"""

@file "generators.md" """
## Random Graphs
*LightGraphs.jl* implements three common random graph generators:

{{erdos_renyi, watts_strogatz, random_regular_graph, random_regular_digraph}}

In addition, [stochastic block model](https://en.wikipedia.org/wiki/Stochastic_block_model)
graphs are available using the following constructs:

{{StochasticBlockModel, make_edgestream}}

`StochasticBlockModel` instances may be used to create Graph objects.

### Static Graphs
*LightGraphs.jl* also implements a collection of classic graph generators:

{{CompleteGraph, CompleteDiGraph, StarGraph, StarDiGraph,PathGraph, PathDiGraph, WheelGraph, WheelDiGraph}}

"""

@file "gettingstarted.md" """
### Core Concepts
A graph *G* is described by a set of vertices *V* and edges *E*:
*G = {V, E}*. *V* is an integer range `1:n`; *E* is represented as forward
(and, for directed graphs, backward) adjacency lists indexed by vertex. Edges
may also be accessed via an iterator that yields `Edge` types containing
`(src::Int, dst::Int)` values.

*LightGraphs.jl* provides two graph types: `Graph` is an undirected graph, and
`DiGraph` is its directed counterpart.

Graphs are created using `Graph()` or `DiGraph()`; there are several options
(see below for examples).

Edges are added to a graph using `add_edge!(g, e)`. Instead of an edge type
integers may be passed denoting the source and destination vertices (e.g.,
`add_edge!(g, 1, 2)`).

Multiple edges between two given vertices are not allowed: an attempt to
add an edge that already exists in a graph will result in a silent failure.

Edges may be removed using `rem_edge!(g, e)`. Alternately, integers may be passed
denoting the source and destination vertices (e.g., `rem_edge!(g, 1, 2)`). Note
that, particularly for very large graphs, edge removal is a (relatively)
expensive operation.

An attempt to remove an edge that does not exist in the graph will result in an
error.

Edge distances for most traversals may be passed in as a sparse or dense matrix
of  values, indexed by `[src,dst]` vertices. That is, `distmx[2,4] = 2.5`
assigns the distance `2.5` to the (directed) edge connecting vertex 2 and vertex 4.
Note that for undirected graphs, `distmx[4,2]` should also be set.

Edge distances for undefined edges are ignored.


### Installation
Installation is straightforward:
```julia
julia> Pkg.install("LightGraphs")
```

*LightGraphs.jl* requires the following packages:

- [GZip](https://github.com/JuliaLang/GZip.jl)
- [StatsBase](https://github.com/JuliaStats/StatsBase.jl)
- [Docile](https://github.com/MichaelHatherly/Docile.jl)
- [LightXML](https://github.com/JuliaLang/LightXML.jl)
- [ParserCombinator](https://github.com/andrewcooke/ParserCombinator.jl)


### Usage Examples
(all examples apply equally to `DiGraph` unless otherwise noted):

```julia
# create an empty undirected graph
g = Graph()

# create a 10-node undirected graph with no edges
g = Graph(10)

# create a 10-node undirected graph with 30 randomly-selected edges
g = Graph(10,30)

# add an edge between vertices 4 and 5
add_edge!(g, 4, 5)

# remove an edge between vertices 9 and 10
rem_edge!(g, 9, 10)

# get the neighbors of vertex 4
neighbors(g, 4)

# show distances between vertex 4 and all other vertices
dijkstra_shortest_paths(g, 4).dists

# as above, but with non-default edge distances
distmx = zeros(10,10)
distmx[4,5] = 2.5
distmx[5,4] = 2.5
dijkstra_shortest_paths(g, 4, distmx=distmx).dists

# graph I/O
g = load("mygraph.jgz", "mygraph")
save("mygraph.jgz", g, "mygraph")
```
"""

@file "index.md" """
# LightGraphs.jl

[![Build Status](https://travis-ci.org/JuliaGraphs/LightGraphs.jl.svg?branch=master)](https://travis-ci.org/JuliaGraphs/LightGraphs.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaGraphs/LightGraphs.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaGraphs/LightGraphs.jl?branch=master)
[![LightGraphs](http://pkg.julialang.org/badges/LightGraphs_release.svg)](http://pkg.julialang.org/?pkg=LightGraphs&ver=release)
[![LightGraphs](http://pkg.julialang.org/badges/LightGraphs_0.4.svg)](http://pkg.julialang.org/?pkg=LightGraphs&ver=nightly)
[![Documentation Status](https://readthedocs.org/projects/lightgraphsjl/badge/?version=latest)](https://readthedocs.org/projects/lightgraphsjl/?badge=latest)
[![Join the chat at https://gitter.im/JuliaGraphs/LightGraphs.jl](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JuliaGraphs/LightGraphs.jl)


An optimized graphs package.

Simple graphs (not multi- or hypergraphs) are represented in a memory- and time-efficient
manner with adjacency lists and edge sets. Both directed and undirected graphs are supported via separate types, and conversion is available from directed to undirected.
"""

@file "integration.md" """
*LightGraphs.jl*'s integration with other Julia packages is designed to be straightforward. Here are a few examples.

### [Graphs.jl](http://github.com/JuliaLang/Graphs.jl)
Creating a Graphs.jl `simple_graph` is easy:
```julia
julia> s = simple_graph(nv(g), is_directed=LightGraphs.is_directed(g))
julia> for e in LightGraphs.edges(g)
           add_edge!(s,src(e), dst(e))
       end
```

### [GraphLayout.jl](https://github.com/IainNZ/GraphLayout.jl)
This excellent graph visualization package can be used with *LightGraphs.jl*
as follows:

```julia
julia> g = WheelGraph(10); am = full(adjacency_matrix(g))
julia> loc_x, loc_y = layout_spring_adj(am)
julia> draw_layout_adj(am, loc_x, loc_y, filename="wheel10.svg")
```
producing a graph like this:
![Wheel Graph](https://cloud.githubusercontent.com/assets/941359/8960521/35582c1e-35c5-11e5-82d7-cd641dff424c.png)

###[TikzGraphs.jl](https://github.com/sisl/TikzGraphs.jl)
Another nice graph visualization package. ([TikzPictures.jl](https://github.com/sisl/TikzPictures.jl)
required to render/save):
```julia
julia> g = WheelGraph(10); t = plot(g)
julia> save(SVG("wheel10.svg"), t)
```
producing a graph like this:
![Wheel Graph](https://cloud.githubusercontent.com/assets/941359/8960499/17f703c0-35c5-11e5-935e-044be51bc531.png)

###[GraphPlot.jl](https://github.com/afternone/GraphPlot.jl)
Another graph visualization package that is very simple to use.
[Compose.jl](https://github.com/dcjones/Compose.jl) is required for most rendering functionality:
```julia
julia> using GraphPlot, Compose
julia> g = WheelGraph(10)
julia> draw(PNG("/tmp/wheel10.png", 16cm, 16cm), gplot(g))
```

###[Metis.jl](https://github.com/JuliaSparse/Metis.jl)
The Metis graph partitioning package can interface with *LightGraphs.jl*:

```julia
julia> g = Graph(100,1000)
{100, 1000} undirected graph

julia> partGraphKway(g, 6)  # 6 partitions
```

###[GraphMatrices.jl](https://github.com/jpfairbanks/GraphMatrices.jl)
*LightGraphs.jl* can interface directly with this spectral graph analysis
package:

```julia
julia> g = PathGraph(10)
{10, 9} undirected graph

julia> a = CombinatorialAdjacency(g)
GraphMatrices.CombinatorialAdjacency{Float64,LightGraphs.Graph,Array{Float64,1}}({10, 9} undirected graph,[1.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,1.0])
```

"""

@file "linalg.md" """
*LightGraphs.jl* provides the following matrix operations on both directed and
undirected graphs:

## Adjacency

{{adjacency_matrix, adjacency_spectrum}}

## Laplacian

{{laplacian_matrix, laplacian_spectrum}}
"""

@file "maximumflow.md" """
*LightGraphs.jl* provides four algorithms for [maximum flow](https://en.wikipedia.org/wiki/Maximum_flow_problem)
computation:

- [Edmonds–Karp algorithm](https://en.wikipedia.org/wiki/Edmonds%E2%80%93Karp_algorithm)
- [Dinic's algorithm](https://en.wikipedia.org/wiki/Dinic%27s_algorithm)
- [Boykov-Kolmogorov algorithm](http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=1316848&tag=1)
- [Push-relabel algorithm](https://en.wikipedia.org/wiki/Push%E2%80%93relabel_maximum_flow_algorithm)

{{maximum_flow}}
"""

@file "operators.md" """
*LightGraphs.jl* implements the following graph operators. In general,
functions with two graph arguments will require them to be of the same type
(either both `Graph` or both `DiGraph`).

{{complement, reverse, reverse!, blkdiag, union, intersect, difference, symmetric_difference, induced_subgraph, join, tensor_product, cartesian_product, crosspath}}
"""

@file "pathing.md" """
*LightGraphs.jl* provides several traversal and shortest-path algorithms, along with
various utility functions. Where appropriate, edge distances may be passed in as a
matrix of real number values. The matrix should be indexed by `[src, dst]` (see [Getting Started](gettingstarted.html) for more information).

## Graph Traversal

*Graph traversal* refers to a process that traverses vertices of a graph following certain order (starting from user-input sources). This package implements three traversal schemes:

* `BreadthFirst`,
* `DepthFirst`, and
* `MaximumAdjacency`.

{{bfs_tree, dfs_tree}}

## Random walks
*LightGraphs* includes uniform random walks and self avoiding walks:

{{randomwalk, saw}}


## Connectivity / Bipartiteness
`Graph connectivity` functions are defined on both undirected and directed graphs:

{{is_connected, is_strongly_connected, is_weakly_connected, connected_components, strongly_connected_components, weakly_connected_components, has_self_loop, attracting_components, is_bipartite, condensation, period}}

## Cycle Detection
In graph theory, a cycle is defined to be a path that starts from some vertex
`v` and ends up at `v`.

{{is_cyclic}}

##Simple Minimum Cut
Stoer's simple minimum cut gets the minimum cut of an undirected graph.

{{mincut, maximum_adjacency_visit}}

## Shortest-Path Algorithms
### General properties of shortest path algorithms
*  The distance from a vertex to itself is always `0`.
* The distance between two vertices with no connecting edge is always `Inf`.

{{a_star, dijkstra_shortest_paths, bellman_ford_shortest_paths, floyd_warshall_shortest_paths}}

## Path discovery / enumeration

{{gdistances, gdistances!, enumerate_paths}}

For Floyd-Warshall path states, please note that the output is a bit different,
since this algorithm calculates all shortest paths for all pairs of vertices: `enumerate_paths(state)` will return a vector (indexed by source vertex) of
vectors (indexed by destination vertex) of paths. `enumerate_paths(state, v)`
will return a vector (indexed by destination vertex) of paths from source `v`
to all other vertices. In addition, `enumerate_paths(state, v, d)` will return
a vector representing the path from vertex `v` to vertex `d`.

### Path States
The `floyd_warshall_shortest_paths`, `bellman_ford_shortest_paths`,
`dijkstra_shortest_paths`, and `dijkstra_predecessor_and_distance` functions
return a state that contains various information about the graph learned during
traversal. The three state types have the following common information,
accessible via the type:

`.dists`
Holds a vector of distances computed, indexed by source vertex.

`.parents`
Holds a vector of parents of each source vertex. The parent of a source vertex
is always `0`.

In addition, the `dijkstra_predecessor_and_distance` function stores the
following information:

`.predecessors`
Holds a vector, indexed by vertex, of all the predecessors discovered during
shortest-path calculations. This keeps track of all parents when there are
multiple shortest paths available from the source.

`.pathcounts`
Holds a vector, indexed by vertex, of the path counts discovered during
traversal. This equals the length of each subvector in the `.predecessors`
output above.
"""

@file "persistence.md" """
## Reading and writing a Graph
Graphs may be written to I/O streams and files using the `save` function and
read with the `load` function. Currently supported graph formats are the
 *LightGraphs.jl* format `lg` and the common formats `gml, graphml, gexf, dot, net`.

{{save, load}}

## Examples
```julia
julia> save(STDOUT, g)
julia> save("mygraph.jgz", g, "mygraph"; compress=true)
julia> g = load("multiplegraphs.jgz")
julia> g = load("multiplegraphs.xml", :graphml)
julia> g = load("mygraph.gml", "mygraph", :gml)
```
"""
