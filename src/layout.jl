export Layout, LForwardReference, LFixedVector, LVarVector
export is_template_fixed, is_template_variable, simple_size, total_size, create_bytes

"""
Layout

All structs used to describe the memory layout (of a C-data structure) need to be
subtypes of this.
Some controlling objects used in such templates to describe vectors and pointers
have also this type.
A `Layout` structure and a memory pointer are needed to construct an `CAccessor` object.
"""
abstract type Layout end

abstract type LVector{T} <: Layout end

Base.eltype(::Type{<:LVector{T}}) where T = T

# Layout Elements
"""
    LFixedVector{T,N}

Denote a fixed size vector with element type `T` and size `N`.
"""
struct LFixedVector{T,N} <: LVector{T}
    p::NTuple{N,T}
end
Base.length(::Type{LFixedVector{T,N}}, ::Any) where {T,N} = N
Base.eltype(::Type{LFixedVector{T,N}}) where {T,N} = T

"""
    LVarVector{T,F}

Denote a variable length vector with element type `T` in a template.
`F` is a function, which calculates the length of the vector, given the
accessor object containing the vector.

Example:
    struct A <: Layout
        len::Int
        vec::NVarVector{Float64, (x) -> x.len}
    end

"""
struct LVarVector{T,F}  <: LVector{T}
    p::NTuple{0,T}
end
Base.length(::Type{LVarVector{T,F}}, x) where {T,F} = F(x)
Base.eltype(::Type{LVarVector{T,F}}) where {T,F} = T

struct LForwardReference{M,L} <: Layout
    p::Ptr{Nothing}
end
Base.eltype(::Type{LForwardReference{M,L}}) where {M,L} = M.name.module.eval(L)

const TEMPLATE_FIXED = true
const TEMPLATE_VAR = false
"""
    is_template_variable(type)

Has the layout described by `type` a variable size
(for example variable sized vector in last field of a struct)?
"""
is_template_variable(T::Type, deep::Bool=false) = !is_template_fixed(T, deep)

"""
    is_template_fixed(type)

Has the layout described by `type` a fixed size.
"""
is_template_fixed(T::Type, deep::Bool=false) = is_template_fixed(T, deep, Dict())
function is_template_fixed(::Type{T}, deep::Bool, dup) where T
    isprimitivetype(T) || throw(ArgumentError("$T is not a supported layout type"))
    TEMPLATE_FIXED
end
function is_template_fixed(::Type{S}, deep::Bool, dup) where {T,S<:Ptr{T}}
    T <: Ptr && throw(ArgumentError("$S is not a supported layout type"))
    get!(dup, S) do
        dup[S] = TEMPLATE_FIXED
        d = is_template_fixed(T, deep, dup)
        deep ? d : TEMPLATE_FIXED
    end
end
function is_template_fixed(::Type{S}, deep::Bool, dup) where {S<:LForwardReference}
    is_template_fixed(Ptr{eltype(S)}, deep, dup)
end
function is_template_fixed(::Type{S}, deep::Bool, dup) where {T,N,S<:LFixedVector{T,N}}
    get!(dup, S) do
        dup[S] = TEMPLATE_FIXED
        k = is_template_fixed(T, deep, dup)
        if N > 1 && k == TEMPLATE_VAR
            throw(ArgumentError("$S with variable length elements"))
        end 
        N == 0 ? TEMPLATE_FIXED : k
    end
end
function is_template_fixed(::Type{S}, deep::Bool, dup) where {T,S<:LVarVector{T}}
    get!(dup, S) do
        dup[S] = TEMPLATE_VAR
        is_template_fixed(T, deep, dup)
        TEMPLATE_VAR
    end
end
function is_template_fixed(::Type{T}, deep::Bool, dup) where {T<:Layout}
    get!(dup, T) do
        k = dup[T] = TEMPLATE_FIXED
        if !isbitstype(T)
            text = isconcretetype(T) ? "bits" : "concrete"
            throw(ArgumentError("$T is not a $text type struct"))
        end
        fields = fieldnames(T)
        n = length(fields)
        for i = 1:n
            f = fields[i]
            F = fieldtype(T, f)
            k = is_template_fixed(F, deep, dup)
            if i < n && k == TEMPLATE_VAR
                throw(ArgumentError("$F has variable length in '$T.$f' - not last field"))
            end
        end
        k
    end
end

"""
    create_bytes(T)

Return a `Vector{UInt8}` capable of keeping all data of an object of type `T`
including structure subfields. Ptr-fields are populated with correct pointers into 
the same vector recursively.
"""
function create_bytes(::Type{T}, veclens=()) where T
    n = total_size(T, veclens) * 2
    buf = fill(UInt8(0x0), n)
    m = create_bytes!(buf, T, 0, veclens)
    resize!(buf, m)
    buf
end

function create_bytes!(bytes::Vector{UInt8}, ::Type{T}, offset, veclens) where T <: Layout
    len = simple_size(T, veclens)
    off = offset
    ptr = pointer_from_vector(bytes) + off
    noff = len
    j = 0
    for i = 1:fieldcount(T)
        f = fieldoffset(T, i)
        p = ptr + f
        off = offset + f
        F = fieldtype(T, i)
        vl = is_template_variable(F, true) ? veclens[j += 1] : ()

        if F <: Union{Ptr,LForwardReference}
            noff = align(noff)
            unsafe_store!(Ptr{Ptr{Nothing}}(p), ptr + noff)
            len = create_bytes!(bytes, eltype(F), noff + offset, vl)
            noff += len
        else
            create_bytes!(bytes, F, off, vl)
        end
    end
    noff
end

function create_bytes!(bytes::Vector{UInt8}, ::Type{T}, offset, veclens) where {N,F,T<:LFixedVector{F,N}}
    len = simple_size(T, veclens)
    off = offset
    ptr = pointer_from_vector(bytes) + off
    noff = len
    j = 0
    for i = 1:N
        vl = is_template_variable(F, true) ? veclens[j += 1] : ()
        f = simple_size(F, vl) * (i - 1)

        if F <: Union{Ptr,LForwardReference}
            noff = align(noff)
            unsafe_store!(ptr + f, ptr + noff)
            len = create_bytes!(bytes, eltype(F), noff + off, vl)
            noff += len
        else
            create_bytes!(bytes, F, offset + f, vl)
        end
    end
    noff
end
function create_bytes!(bytes::Vector{UInt8}, ::Type{T}, offset, veclens) where {F,T<:LVarVector{F}}
    len = simple_size(T, veclens)
    off = offset
    ptr = pointer_from_vector(bytes) + off
    noff = len
    vlen(i) = i <= length(veclens) ? veclens[i] : ()
    j = 0
    N = vlen(j += 1)
    for i = 1:N
        vl = is_template_variable(F, true) ? vlen(j += 1) : ()
        f = simple_size(F, vl) * (i - 1)

        if F <: Union{Ptr,LForwardReference}
            noff = align(noff)
            unsafe_store!(ptr + f, ptr + noff)
            len = create_bytes!(bytes, eltype(F), noff + off, vl)
            noff += len
        else
            create_bytes!(bytes, F, off + f, vl)
        end
    end
    noff
end

function create_bytes!(::Vector{UInt8}, ::Type{T}, offset, veclens) where T
    simple_size(T, ())
end

function align(p::Integer, s::Integer=sizeof(Ptr)) # s must be 2^n
    t = s - 1
    (p + t )  & ~t
end

simple_size(T::Type, veclens) = blength(T, veclens, Val(false))
total_size(T::Type, veclens) = blength(T, veclens, Val(true))

function blength(::Type{T}, veclens, v::Val{P}) where {P,F,N,T<:LFixedVector{F,N}}
    s = sizeof(T)
    j = 0
    for _ = 1:N
        j, s = blength_helper(F, veclens, j, s, v, T)
    end
    if j < length(veclens)
        throw(ArgumentError("too many variable length specifiers for $T only $j are needed"))
    end
    s
end

function blength(::Type{T}, veclens, v::Val{P}) where {P,S,T<:LVarVector{S}}
    isempty(veclens) && return 0
    n = first(veclens)
    n == 0 && return 0
    vl(i) = i < length(veclens) ? veclens[i+1] : ()
    sum(blength(S, vl(i), v) for i = 1:n)
end

blength(::Type{Ptr{T}}, veclens, v::Val{P}) where {P,T} = P ? blength(T, veclens, v) : 0

function blength(::Type{T}, veclens, v::Val{P}) where {P,T<:Layout}
    s = sizeof(T)
    j = 0
    for i = 1:fieldcount(T)
        F = fieldtype(T, i)
        j, s = blength_helper(F, veclens, j, s, v, T)
    end
    if j < length(veclens)
        throw(ArgumentError("too many variable length specifiers for $T- only $j are needed"))
    end
    s
end

blength(::Type{T}, veclens, ::Val) where T = sizeof(T)

function blength_helper(::Type{F}, veclens, j, s, v::Val{P}, T) where {P,F}
    if is_template_variable(F, true)
        j += 1
        if j > length(veclens)
            throw(ArgumentError("not enough variable length specifiers for $T"))
        end
        vl = veclens[j]
    else
        vl = ()
    end
    al = Base.datatype_alignment(F)
    s = align(s, al)
    s += F <: LVarVector ? blength(F, vl, v) :
        P && F <: Union{Ptr,LForwardReference} ? blength(eltype(F), vl, v) : 0

    j, s
end
