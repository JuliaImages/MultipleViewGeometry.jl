using MultipleViewGeometry
using Test

@testset "MultipleViewGeometry.jl" begin

    @testset "Basic Set" begin
        p1 = EuclideanPoint((5.0, 3.0))
        p2 = HomogeneousPoint((5.0, 3.0, 1.0))
        p3 = HomogeneousPoint((10.0, 6.0, 2.0); zone=false)
    
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
    end 
end
