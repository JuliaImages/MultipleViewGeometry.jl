module MultipleViewGeometry

using Reexport

using CoordinateTransformations
using Rotations
using StaticArrays
using Distances
using Combinatorics
using LinearAlgebra

include("basic_set.jl")

function stereo_setup end
function show_output end
function calibrate end

export EuclideanPoint, HomogeneousPoint
export Edge, EuclideanNorm, MidPoint, Euclidean

# from checkerboard.jl
export innercorners, allcorners, markcorners
export segboundariescheck
export checkboundaries
export process_image
export nonmaxsuppresion
export kxkneighboardhood
export drawdots!
export draw_rect

export stereo_setup
export show_output

export calibrate

end
