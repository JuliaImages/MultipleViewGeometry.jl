
# EuclideanPoint with x and y coordinates
struct EuclideanPoint
    x::Float64
    y::Float64

    function EuclideanPoint(x::Float64, y::Float64)
        new(x, y)
    end

    function EuclideanPoint(x::Int, y::Int)
        new(x, y)
    end

end

# HomogeneousPoint with x, y, z
# include ideal points and ideal points are not representable in euclidean point
struct HomogeneousPoint
    x::Float64
    y::Float64
    z::Float64

    function HomogeneousPoint(x::Float64, y::Float64)
        new(x, y, 1)
    end

    function HomogeneousPoint(x::Float64, y::Float64, z::Float64; zone=true)
        @assert z != 0
        zone ? new(x / z, y / z, 1) : new(x, y, z)
    end

    function HomogeneousPoint(x::Int, y::Int, z::Int; zone=true)
        @assert z != 0
        zone ? new(x / z, y / z, 1) : new(x, y, z)
    end

end

# conversions between EuclideanPoint and HomogeneousPoint
# ----------------------------------------------------------
function EuclideanPoint(Point1::HomogeneousPoint)
    EuclideanPoint(Point1.x/Point1.z, Point1.y/Point1.z)
end

function HomogeneousPoint(Point1::EuclideanPoint; k = 1.0)
    HomogeneousPoint(Point1.x * k, Point1.y * k, k)
end
# ----------------------------------------------------------

# equality tests between different types of points
# ----------------------------------------------------------
function Base.:(==)(Point1::HomogeneousPoint, Point2::HomogeneousPoint)
    return Point1.x / Point1.z == Point2.x / Point2.z && Point1.y / Point1.z == Point2.y / Point2.z
end

function Base.:(==)(Point1::EuclideanPoint, Point2::EuclideanPoint)
    return Point1.x == Point2.x && Point1.y == Point2.y
end

function Base.:(==)(Point1::HomogeneousPoint, Point2::EuclideanPoint)
    return Point1.x / Point1.z == Point2.x && Point1.y / Point1.z == Point2.y
end

function Base.:(==)(Point1::EuclideanPoint, Point2::HomogeneousPoint)
    return Point1.x == Point2.x / Point2.z && Point1.y == Point2.y / Point2.z
end
# ----------------------------------------------------------
