using Dates: DateTime, now, UTC
using CStructures: default_value

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
function filter_ops(mod::Module, fs)
    res = fill(C_NULL, length(fieldnames(FuseLowlevelOps)))
    for (i, f) in enumerate(fieldnames(FuseLowlevelOps))
        if (c = getp(mod, f, noop)) != noop
            res[i] = gen_callback(f, c, fs)
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
    gen_callback(name::Symbol, f::Function, fs::Any)

Call the function named `Symbol('G', name)` (for example `Gread`), which
generates a C-callable closure of type `CFunction`, dedicated to call back the Julia
function `f(fs, ...)` (for example `read(fs, req, ...)`).

Return the pointer of `CFunction`, which can be passed as a C-callback to `ccall`
activations.
"""
function gen_callback(name::Symbol, c::Function, fs::Any)
    gf = Symbol('G', name)
    gfunction = getproperty(FuseApi, gf)
    g = gfunction(c, fs)
    Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, g))
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
        println("docall($f, $req)")
        if req.pointer === C_NULL
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
function main_loop(args::AbstractVector{String}, fs::Module, user_data=nothing)
    user_data_r = Ref(user_data)
    GC.@preserve user_data_r _main_loop(args, fs, user_data)
end
function _main_loop(args, fs, user_data)
        fargs = create_args("command", args)
        opts = fuse_parse_cmdline(fargs)
        callbacks = filter_ops(fs, user_data)
        copycb = copy(callbacks)
        se = fuse_session_new(fargs, callbacks)
        se == C_NULL && throw(ArgumentError("fuse_session_new failed $rc"))
        rc = fuse_session_mount(se, opts.mountpoint)
        rc != 0 && throw(ArgumentError("fuse_session_mount failed $rc"))

        cfg = FuseLoopConfig(opts.clone_fd, opts.max_idle_threads)
        rc = opts.singlethread ? fuse_session_loop(se) : fuse_session_loop_mt(se, cfg)
        rc != 0 && throw(ArgumentError("fuse_session_loop failed $rc"))
        check_callbacks(callbacks, copycb)
        fuse_session_unmount(se)
        fuse_session_destroy(se)
end

function check_callbacks(a, b)
    a == b
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
