module MultipleViewGeometry

using Reexport

using CoordinateTransformations
using Rotations
using StaticArrays
using Distances
using Combinatorics
using LinearAlgebra

include("basic_set.jl")
include("homography.jl")

function stereo_setup end
function show_output end
function detect_boards end
function calibrate end

function compute_view_based_homography end
function get_normalization_matrix end
function normalize_points end
function get_intrinsic_parameters end

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

export detect_boards
export calibrate
export normalize_points

export gethomography
export get_normalization_matrix
export compute_view_based_homography
export get_intrinsic_parameters

end
