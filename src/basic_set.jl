
import Base: convert

abstract type AbstractPoint end

mutable struct EuclideanPoint <: AbstractPoint
    cords::NTuple

    function EuclideanPoint(cords::NTuple)
        new(cords)
    end
end

mutable struct HomogeneousPoint <: AbstractPoint
    cords::NTuple

    function HomogeneousPoint(cords::NTuple; zone = true)
        @assert cords[end] != 0
        zone ? new(cords ./ cords[end]) : new(cords) 
    end
end

# conversions between EuclideanPoint and HomogeneousPoint
# ----------------------------------------------------------
function EuclideanPoint(Point1::HomogeneousPoint)
    EuclideanPoint((Point1.cords ./ Point1.cords[end])[1:end-1])
end

function HomogeneousPoint(Point1::EuclideanPoint; k = 1.0)
    HomogeneousPoint(((Point1.cords .* k)..., k))
end
# ----------------------------------------------------------

# equality tests between different types of points
# ----------------------------------------------------------
function Base.:(==)(Point1::HomogeneousPoint, Point2::HomogeneousPoint)
    return Point1.cords ./ Point1.cords[end] == Point2.cords ./ Point2.cords[end]
end

function Base.:(==)(Point1::EuclideanPoint, Point2::EuclideanPoint)
    return Point1.cords == Point2.cords
end

function Base.:(==)(Point1::HomogeneousPoint, Point2::EuclideanPoint)
    return (Point1.cords ./ Point1.cords[end])[1:end-1] == Point2.cords
end

function Base.:(==)(Point1::EuclideanPoint, Point2::HomogeneousPoint)
    return (Point2.cords ./ Point2.cords[end])[1:end-1] == Point1.cords
end
# ----------------------------------------------------------

# Operators between points
# ----------------------------------------------------------
function Base.:(+)(Point1::T, Point2::T) where T <: AbstractPoint
    return typeof(Point1)(Point1.cords .+ Point2.cords)
end

function Base.:(-)(Point1::T, Point2::T) where T <: AbstractPoint
    return typeof(Point1)(Point1.cords .- Point2.cords)
end

function Base.:(/)(Point1::T, k::Int) where T <: AbstractPoint
    return typeof(Point1)((Point1.cords ./ k)[1:end-1])
end
# -----------------------------------------------------------

mutable struct Edge{T<:AbstractPoint}
    p1::T
    p2::T
end


