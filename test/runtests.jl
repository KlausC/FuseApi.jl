using SQLiteFs
using Test

@testset "SQLiteFs.jl" begin
    include("cstruct.jl")
    include("layout.jl")
end
