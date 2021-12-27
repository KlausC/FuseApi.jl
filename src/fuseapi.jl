using Dates: DateTime, now, UTC

export timespec_now, main_loop

"""
    noop(args...)

Dummy function - should never by actually called.
If it is called, it behaves as if the function was not supported.
"""
noop(args...) = UV_ENOTSUP

"""
    filter_ops(m::Module)

Return a vector of C-callable function pointers for functions with names
as defined in `FuseApi.FuseLowlevelOps`.

For functions, which are not exported by `module`, a null pointer is generated
to indicate to `fuselib3`, that this function is not supported.
"""
function filter_ops(fs::Module)
    res = fill(C_NULL, length(fieldnames(FuseLowlevelOps)))
    for (i, f) in enumerate(fieldnames(FuseLowlevelOps))
        if (c = getp(fs, f, noop)) != noop
            res[i] = gen_callback(f, c)
        end     
    end
    res
end

"""
    getp(m::Module, f::Symbol, default::Function)

Return the function named `f`, if defined and exported in module `m`,
otherwise the default value.
"""
function getp(m, f::Symbol, default::Function)
    try
        if f in names(m) && isdefined(m, f)
            getproperty(m, f)
        else
            default
        end
    catch
        default
    end
end

"""
    gen_callback(n::Symbol, f::Function)

Call the function named `Symbol('G', n)` (for example `Gread`), which
generates a C-callable closure of type `CFunction`, dedicated to call back the Julia
function `f` (for example `read`).

Return the pointer of `CFunction`, which can be passed as a C-callback to `ccall`
activations.
"""
function gen_callback(f::Symbol, c::Function)
    gf = Symbol('G', f)
    gfunction = getproperty(FuseApi, gf)
    gfunction(c).ptr
end

"""
    docall(f, req)

Provides common frame for all req-related C-callback functions
If the actual callback function throws or returns a value != 0
An error reply is returned.
"""
function docall(f::Function, req::FuseReq)
    error = Base.UV_ENOTSUP
    try
        error = f()
    catch
        error = Base.UV_EACCES
        rethrow()
    finally
        if error != 0
            fuse_reply_err(req, abs(error))
        end
        nothing
    end
    nothing
end

"""
    docall(f)

Frame for `init` and `destroy`
"""
function docall(f::Function)
    try
        f()
    finally
        nothing
    end
    nothing
end

function create_args(cmd::String, arg::AbstractVector{String})
    data = Cserialize(FuseCmdlineArgs, (argc = length(arg) + 1, argv = [cmd, arg..., nothing]))
    CStructGuarded{FuseCmdlineArgs}(data)
end

"""
    main_loop(cmdline_args::Vector{String}, fs::Module)

Set up and start a Fuse session. Use commandline arguments `cmdline_args`
and the filesystem implementation defined in module `fs`.

Module `fs` must define and export all supported callback functions, the names
of which are specified in `FuseLowlevelOps`.
"""
function main_loop(args::AbstractVector{String}, fs::Module, user_data=nothing)

        fargs = create_args("command", args)
        opts = fuse_parse_cmdline(fargs)
        mountpoint = opts.mountpoint
        println("parsed mountpoint $(mountpoint)")

        callbacks = filter_ops(fs)
        se = fuse_session_new(fargs, callbacks, user_data)
        se == C_NULL && throw(ArgumentError("fuse_session_new failed"))

        println("going to mount at $(mountpoint)")
        rc = fuse_session_mount(se, mountpoint)
        rc != 0 && throw(ArgumentError("fuse_session_mount failed"))

        println("mounted at $(mountpoint) - starting loop")
        rc = fuse_session_loop(se)
        rc != 0 && throw(ArgumentError("fuse_session_loop failed"))

        fuse_session_unmount(se)
        GC.@preserve user_data fuse_session_destroy(se)
end

function fuse_parse_cmdline(args::CStructAccess{FuseCmdlineArgs})
    opts = Cserialize(FuseCmdlineOpts, ())
    popts = pointer(opts)
    ccall((:fuse_parse_cmdline, :libfuse3), Cint, (Ptr{FuseCmdlineArgs}, Ptr{UInt8}), args, popts)
    CStructGuarded{FuseCmdlineOpts}(opts)
end

function log(args...)
    flush(stderr)
    println(stderr, args...)
end


# Base.unsafe_convert(::Type{Ptr{FuseReq}}, cs::FuseReq) where T = Ptr{FuseReq}(cs.pointer)
function Base.unsafe_convert(::Type{Ptr{T}}, s::SubArray{T,1}) where T
    Ptr{T}(pointer(s.parent)) + first(s.indices[1]) - 1
end

Base.convert(::Type{Timespec}, t::CStruct{Timespec}) = Timespec(t.seconds, t.nanoseconds)

"""
    timespec_now()

Current time in `Timespec` format (seconds and nanoseconds)
"""
function timespec_now()
    a = (now(UTC) - DateTime(1970, 1, 1)).value
    s, n = fldmod(a, 10^3)
    n *= 10^6
    Timespec(s, n)
end
