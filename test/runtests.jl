using MultipleViewGeometry
using Test

@testset "MultipleViewGeometry.jl" begin

    @testset "Basic Set" begin
        p1 = EuclideanPoint((5.0, 3.0))
        p2 = HomogeneousPoint((5.0, 3.0, 1.0))
        p3 = HomogeneousPoint((10.0, 6.0, 2.0); zone=false)
        p4 = EuclideanPoint((5.0, 7.0))

        # verifies that point always has x, y and their values are correct
        @test p1.cords[1] == 5.0 && p1.cords[2] == 3.0

        # verifies that point always has x, y, z and their values are correct
        @test p2.cords[1] == 5.0 && p2.cords[2] == 3.0 && p2.cords[3] == 1.0
        
        # verifies that keyword zone handles divide part properly
        @test p3.cords[1] == 10.0 && p3.cords[2] == 6.0 && p3.cords[3] == 2.0

        # verifies EuclideanPoints are correctly compared
        @test p1 == p1

        # verifies HomogeneousPoints are correctly compared
        @test p2 == p2
        @test p2 == p3

        # verifies EuclideanPoint and HomogeneousPoint are correctly compared
        @test p1 == p2
        @test p2 == p1

        # verifies that assertions are done correctly
        @test_throws AssertionError HomogeneousPoint((1.0, 1.0, 0.0))
        @test_throws AssertionError HomogeneousPoint((1, 1, 0))

        # verifies that it doesn't work when all inputs are not of same type
        @test_throws MethodError HomogeneousPoint((1, 1, 0.0))

        # verifies conversions between HomogeneousPoint and EuclideanPoint
        @test p1 == EuclideanPoint(p2)
        @test p1 == EuclideanPoint(p3)
        
        @test p2 == HomogeneousPoint(p1)
        @test p3 == HomogeneousPoint(p1)

        # verifies if summation works
        @test p1 + p4 == EuclideanPoint((10.0, 10.0))

        # verifies if scaling works
        p5 = EuclideanPoint((4, 2))
        @test (1.5) * p5 == EuclideanPoint((6.0, 3.0))

        # verifies mid point  computation works
        @test MidPoint(p1, p5) == EuclideanPoint((4.5, 2.5))

        # verfies if norm calculation works
        @test EuclideanNorm(p5) == 4.47213595499958
    end 

    @testset "Vector laws Test" begin
        p1 = EuclideanPoint((1.0,2.0,3.0))
        p2 = EuclideanPoint((2.0,4.0,6.0))
        p3 = EuclideanPoint((3.0,5.0,7.0))

        p4 = EuclideanPoint((0,0,0))

        # verifies commutative and abelian
        @test p1 + p2 == p2 + p1 
        
        # verifies scaling
        @test 2 * p1 == p2
        
        # verifies associativity 
        @test p1 + (p2 + p3) == (p1 + p2) + p3
        
        # verifies zero vector 
        @test p1 + p4 ==  p4 + p1

        # verifies -ve + ve sum
        @test p1 + (-p1) == EuclideanPoint((0.0,0.0,0.0))

        # verifies multiply by one
        @test 1 * p1 == p1

        # verifies associativity of multiplication
        @test 4 * p1 == 2 * (2 * p1)

        # verifies distributivity of multiplication
        @test 2 * (p1 + p2) == 2 * p1 + 2 * p2
        @test (2 + 1) * p1 == 2 * p1 + 1 * p1
    end

    @testset "Modelling a cube" begin
        vertices = [] 
        for i in [-1,1]
            for j in [-1,1]
                for k in [-1,1]
                    push!(vertices, EuclideanPoint((i, j, k)))
                end
            end
        end

        @test length(vertices) == 8 # it's a cube

        function dist(p; dist = 2)
            Euclidean()(p[1].cords,p[2].cords) == dist
        end

        edges = filter(dist, collect(combinations(vertices, 2)))

        @test length(edges) == 12 # 12 edges in a cube

        camera_loc = EuclideanPoint((2,3,5))
        camera_focallength = 1

        final_edges = []
        for edge in edges
            vertices_diffcord = map(i-> i - camera_loc, edge)

            cords = map(i -> i / i.cords[end], vertices_diffcord)
            push!(final_edges, Edge(cords[1], cords[2]))
        end

        @test length(final_edges) == 12 # modified edges

        # using GLMakie
        # f = Figure()
        # Axis(f[1, 1])

        # for i in final_edges
        #     linesegments!([i.p1.cords[1], i.p2.cords[1]], [i.p1.cords[2], i.p2.cords[2]])
        # end
    end

    @testset "homography" begin
        src=CartesianIndex{2}[]
        push!(src, CartesianIndex(1,1))
        push!(src, CartesianIndex(2,1))
        push!(src, CartesianIndex(3,1))
        push!(src, CartesianIndex(3,3))
        push!(src, CartesianIndex(1,3))
    
        des=CartesianIndex{2}[]
        push!(des, CartesianIndex(1,1))
        push!(des, CartesianIndex(3,1))
        push!(des, CartesianIndex(5,1))
        push!(des, CartesianIndex(4,4))
        push!(des, CartesianIndex(2,4))
    
        H = gethomography(src, des)
    
        @test H[3,3]==1
    
        p=H*[1, 1, 1]
        p/=p[3]
        @test_approx_eq p[1] 1
        @test_approx_eq p[2] 1
    
        p=H*[1, 2, 1]
        p/=p[3]
        @test_approx_eq p[1] 5/3
        @test_approx_eq p[2] 3
    end
end