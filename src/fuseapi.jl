using Dates: DateTime, now, UTC
using CStructures: default_value
using Base: CFunction

export timespec_now, main_loop

"""
    noop(args...)

Dummy function - should never by actually called.
If it is called, it behaves as if the function was not supported.
"""
noop(args...) = UV_ENOTSUP
dummy = @cfunction $noop Cint ()

"""
    filter_ops(m::Module)

Return a vector of C-callable function pointers for functions with names
as defined in `FuseApi.FuseLowlevelOps`.

For functions, which are not exported by `module`, a null pointer is generated
to indicate to `fuselib3`, that this function is not supported.
"""
function filter_ops(mod::Module, fs, cbhandles)
    n = length(fieldnames(FuseLowlevelOps))
    resize!(cbhandles, n)
    fill!(cbhandles, dummy)
    res = fill(C_NULL, n)
    for (i, f) in enumerate(fieldnames(FuseLowlevelOps))
        if (cf = getp(mod, f, noop)) != noop
            cb = gen_callback(f, cf, fs)
            cbhandles[i] = cb
            res[i] = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, cb))
        end
    end
    FuseLowlevelOps(res...)
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
    gen_callback(name::Symbol, f::Function, fs::Any)

Call the function named `Symbol('G', name)` (for example `Gread`), which
generates a C-callable closure of type `CFunction`, dedicated to call back the Julia
function `f(fs, ...)` (for example `read(fs, req, ...)`).

This closure serves as a GC-handle for the function pointer, which is actually passed
as a callback to be called from a C-environment.
"""
function gen_callback(name::Symbol, c::Function, fs::Any)
    gf = Symbol('G', name)
    gfunction = getproperty(FuseApi, gf)
    gfunction(c, fs)
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
        if req.pointer === C_NULL
            ccall(:jl_breakpoint, Cvoid, (Any,), f)
            throw(ArgumentError("docall($f, $req) - req was zero!!!"))
        end
        error = f()
    catch
        error = Base.UV_EACCES
        rethrow()
    finally
        if error != 0 && req.pointer !== C_NULL
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

"""
    create_args(cmd::String, args::AbstractVector{String})

Return CStructGuarded{FuseCmdlineArgs} object to pass arguments to C. 
"""
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
function main_loop(args::AbstractVector{String}, mod::Module, user_data=nothing)
    user_data_r = Ref(user_data)
    cbhandles = CFunction[]
    # it is essential, that user_data and cbhandles are protected from GC
    # during the active time of _main_loop.
    GC.@preserve user_data_r cbhandles _main_loop(args, mod, user_data, cbhandles)
end
function _main_loop(args, mod, user_data, cbhandles)
        fargs = create_args("command", args)
        opts = fuse_parse_cmdline(fargs)
        callbacks = filter_ops(mod, user_data, cbhandles)
        se = fuse_session_new(fargs, callbacks)
        se == C_NULL && throw(ArgumentError("fuse_session_new failed $rc"))
        rc = fuse_session_mount(se, opts.mountpoint)
        rc != 0 && throw(ArgumentError("fuse_session_mount failed $rc"))

        cfg = FuseLoopConfig(opts.clone_fd, opts.max_idle_threads)
        rc = opts.singlethread ? fuse_session_loop(se) : fuse_session_loop_mt(se, cfg)
        rc != 0 && throw(ArgumentError("fuse_session_loop failed $rc"))
        fuse_session_unmount(se)
        fuse_session_destroy(se)
end

"""
    fuse_parse_cmdline(args::CStructAccess{FuseCmdlineArgs})

Return FuseCmdlineOpts object with selected options and mountpoint from the cmdline.
"""
function fuse_parse_cmdline(args::CStructAccess{FuseCmdlineArgs})
    opts = Cserialize(LFuseCmdlineOpts, ())
    popts = pointer(opts)
    ccall((:fuse_parse_cmdline, :libfuse3), Cint, (Ptr{FuseCmdlineArgs}, Ptr{UInt8}), args, popts)
    default_value(FuseCmdlineOpts, CStruct{LFuseCmdlineOpts}(opts))
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
