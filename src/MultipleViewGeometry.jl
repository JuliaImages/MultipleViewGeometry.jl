module MultipleViewGeometry

using Reexport

@reexport using CoordinateTransformations
@reexport using Rotations
@reexport using StaticArrays
@reexport using Distances
@reexport using Combinatorics
using LinearAlgebra

include("basic_set.jl")

export EuclideanPoint, HomogeneousPoint
export Edge, EuclideanNorm, MidPoint, Euclidean

end
