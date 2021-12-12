

struct A1 <: Layout
    a::Bool
    b::Cint
    c::Float64
    d::Cstring
end


@testset "field access" begin
    a = fill(UInt64(0), 3)
    p = pointer_from_vector(a)
    cs = CStruct{A1}(p)
    @test cs.a == 0
    @test cs.b == 0
    @test cs.c == 0
    @test cs.d == ""
    v1 = true
    v2 = 0x12345678
    v3 = 47.11
    v4 = "hallo"
    cs.a = v1
    cs.b = v2
    cs.c = v3
    cs.d = v4
    @test cs.a == v1
    @test cs.b == v2
    @test cs.c == v3
    @test cs.d == v4
end

@testset "index access" begin
    a = fill(UInt64(0), 100)
    p = pointer_from_vector(a)
    cv = CVector{Int}(p, 3)
    @test length(cv) == 3
    cv[1:3] .= (1, 2, 3)
    @test cv[2] == 2
    @test cv[[1,3]] == [1, 3]
end

struct A2 <: Layout
    a::Ptr{A2}
end

@testset "self-referencing" begin
    a = fill(UInt8(0), 100)
    p = pointer_from_vector(a)
    cs = CStruct{A2}(p)
    @test cs.a === nothing
    io = IOBuffer()
    show(io, cs)
    @test String(take!(io)) == "CStruct{A2}(nothing)"
    cs.a = cs
    @test cs.a === cs
    show(io, cs)
    @test String(take!(io)) == "CStruct{A2}(CStruct{A2}(#= circular reference @-1 =#))"
end

struct A3 <: Layout
    len::Int
    vec::LVarVector{Float64, (x) -> x.len}
end

@testset "variable vector at end of struct" begin
    a = fill(Int(0), 1024)
    p = pointer_from_vector(a)
    LEN = 25
    cs = CStruct{A3}(p)
    cs.len = LEN
    @test cs.vec isa CVector{Float64}
    @test length(cs.vec) == cs.len == LEN
end

struct A4 <: Layout
    len::Int
    vec::Ptr{LVarVector{Float64, (x) -> x.len}}
end

@testset "pointer to variable vector" begin
    a = fill(Int(0), 1024)
    p = pointer_from_vector(a)
    a[2] = p + 32
    LEN = 25
    cs = CStruct{A4}(p)
    cs.len = LEN
    @test cs.vec isa CVector{Float64}
    @test length(cs.vec) == cs.len == LEN
end
