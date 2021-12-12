
export FuseLowlevelOps, register, main_loop
export FuseFileInfo, FuseEntryParam, FuseArgs, FuseCmdlineOpts, FuseReq, FuseIno
export Cstat, Cflock

import Base.CFunction

const CFu = Ptr{Cvoid}

struct FuseLoopConfig
    clone_fd::Cint
    max_idle_threads::Cuint
end

struct FuseArgs <: Layout
    argc::Cint
    argv::Ptr{LVarVector{Cstring, (x) -> x.argc}}
    allocated::Cint
end

struct FuseCmdlineOpts
    singlethread::Cint
    foreground::Cint
    debug::Cint
    nodefault_subtype::Cint
    mountpoint::Cstring
    show_version::Cint
    show_help::Cint
    clone_fd::Cint
    max_idle_threads::Cuint
end

struct FuseSession <: Layout
end
struct FuseLowlevelOps
    init::CFu
    destroy::CFu
    lookup::CFu
    forget::CFu
    getattr::CFu
    setattr::CFu
    readlink::CFu
    mknod::CFu
    mkdir::CFu
    unlink::CFu
    rmdir::CFu
    symlink::CFu
    rename::CFu
    link::CFu
    open::CFu
    read::CFu
    write::CFu
    flush::CFu
    release::CFu
    fsync::CFu
    opendir::CFu
    readdir::CFu
    releasedir::CFu
    fsyncdir::CFu
    statfs::CFu
    setxattr::CFu
    getxattr::CFu
    listxattr::CFu
    removexattr::CFu
    access::CFu
    create::CFu
    getlk::CFu
    setlk::CFu
    bmap::CFu
    ioctl::CFu
    poll::CFu
    write_buf::CFu
    retrieve_reply::CFu
    forget_multi::CFu
    flock::CFu
    fallocate::CFu
    readdirplus::CFu
    copy_file_range::CFu
    lseek::CFu
end
const F_SIZE = sizeof(FuseLowlevelOps) ÷ sizeof(Ptr)

const FuseIno = UInt64
const FuseMode = UInt32
const FuseDev = UInt64

const Cuid_t = UInt32
const Cgid_t = UInt32
const Coff_t = Csize_t
const Coff64_t = UInt64
const Cpid_t = Cint
const Cfsblkcnt_t = UInt64
const Cfsfilcnt_t = UInt64

struct FuseBufFlags
    flag::Cint
end
const FUSE_BUF_IS_FD = FuseBufFlags(1 << 1)
const FUSE_BUF_FD_SEEK = FuseBufFlags(1 << 2)
const FUSE_BUF_FD_RETRY = FuseBufFlags(1 << 3)

struct FuseBufCopyFlags
    flag::Cint
end
const FUSE_BUF_NO_SPLICE = FuseBufCopyFlags(1 << 1)
const FUSE_BUF_FORCE_SPLICE = FuseBufCopyFlags(1 << 2)
const FUSE_BUF_SPLICE_MOVE = FuseBufCopyFlags(1 << 3)
const FUSE_BUF_SPLICE_NONBLOCK = FuseBufCopyFlags(1 << 4)

"""
    FuseReq

Opaque structure containing the pointer as obtained by fuselib.
"""
struct FuseReq
    pointer::Ptr{Nothing}
end

struct Timespec <: Layout
    seconds::Int64
    ns::Int64
end

struct FuseCtx <: Layout
    uid::UInt32
    gid::UInt32
    pid::UInt32
    umask::FuseMode
end

struct Cstat <: Layout
    dev     :: UInt64
    ino     :: UInt64
    nlink   :: UInt64
    mode    :: FuseMode
    uid     :: Cuid_t
    gid     :: Cgid_t
    pad0    :: UInt32
    rdev    :: UInt64
    size    :: Int64
    blksize :: Int64
    blocks  :: Int64
    atime   :: Timespec
    mtime   :: Timespec
    ctime   :: Timespec
end
struct FuseEntryParam <: Layout
    ino::FuseIno
    generation::UInt64
    attr::Cstat
    attr_timeout::Cdouble
    entry_timeout::Cdouble
end

# Capability bits for 'fuse_conn_info.capable' and 'fuse_conn_info.want'
 
const FUSE_CAP_ASYNC_READ = Cuint(1 << 0)
const FUSE_CAP_POSIX_LOCKS = Cuint(1 << 1)
const FUSE_CAP_ATOMIC_O_TRUNC = Cuint(1 << 3)
const FUSE_CAP_EXPORT_SUPPORT = Cuint(1 << 4)
const FUSE_CAP_DONT_MASK = Cuint(1 << 6)
const FUSE_CAP_SPLICE_WRITE = Cuint(1 << 7)
const FUSE_CAP_SPLICE_MOVE = Cuint(1 << 8)
const FUSE_CAP_SPLICE_READ = Cuint(1 << 9)
const FUSE_CAP_FLOCK_LOCKS = Cuint(1 << 10)
const FUSE_CAP_IOCTL_DIR = Cuint(1 << 11)
const FUSE_CAP_AUTO_INVAL_DATA = Cuint(1 << 12)
const FUSE_CAP_READDIRPLUS = Cuint(1 << 13)
const FUSE_CAP_READDIRPLUS_AUTO = Cuint(1 << 14)
const FUSE_CAP_ASYNC_DIO = Cuint(1 << 15)
const FUSE_CAP_WRITEBACK_CACHE = Cuint(1 << 16)
const FUSE_CAP_NO_OPEN_SUPPORT = Cuint(1 << 17)
const FUSE_CAP_PARALLEL_DIROPS = Cuint(1 << 18)
const FUSE_CAP_POSIX_ACL = Cuint(1 << 19)
const FUSE_CAP_HANDLE_KILLPRIV = Cuint(1 << 20)
const FUSE_CAP_CACHE_SYMLINKS = Cuint(1 << 23) 
const FUSE_CAP_NO_OPENDIR_SUPPORT = Cuint(1 << 24)
const FUSE_CAP_EXPLICIT_INVAL_DATA = Cuint(1 << 25)

struct FuseConnInfo <: Layout
    proto_major::Cuint
    proto_minor::Cuint
    max_write::Cuint
    max_read::Cuint
    max_readahead::Cuint
    capable::Cuint
    want::Cuint
    max_backgrount::Cuint
    congestion_threshold::Cuint
    time_gran::Cuint
    reserved::LFixedVector{Cuint,22}
end

# bit masks for 2nd field of FuseFileInfo
const FUSE_FI_WRITEPAGE = Cuint(1 << 0)
const FUSE_FI_DIRECT_IO = Cuint(1 << 1)
const FUSE_FI_KEEP_CACHE = Cuint(1 << 2)
const FUSE_FI_FLUSH = Cuint(1 << 3)
const FUSE_FI_NONSEEKABLE = Cuint(1 << 4)
const FUSE_FI_CACHE_READDIR = Cuint(1 << 5)

struct FuseFileInfo <: Layout
    flags::Cint
    bits::Cuint
    fh::UInt64
    lock_owner::UInt64
    poll_events::UInt32
end

struct Cflock
    type::Cshort
    whence::Cshort
    start::Coff64_t
    len::Coff64_t
    pid::Cpid_t
end
struct Ciovec
    base::Ptr{Cvoid}
    len::Csize_t
end
struct Cstatvfs
    bsize::Culong
    frsize::Culong
    blocks::Cfsblkcnt_t
    bfree::Cfsblkcnt_t
    bavail::Cfsblkcnt_t
    files::Cfsfilcnt_t
    ffree::Cfsfilcnt_t
    favail::Cfsfilcnt_t
    fsid::Clong
    flag::Culong
    namemax::Culong
    __spare::NTuple{6,Cint}
end

struct FusePollHandle
end
struct FuseBuf <: Layout
    size::Csize_t
    flags::FuseBufFlags
    mem::Ptr{Cvoid}
    fd::Cint
    pos::Coff_t
end
struct FuseBufvec <: Layout
    count::Csize_t
    idx::Csize_t
    off::Csize_t
    buf::LVarVector{FuseBuf}
end
struct FuseForgetData
end

const FUSE_IOCTL_COMPAT = Cuint(1 << 0)
const FUSE_IOCTL_UNRESTRICTED = Cuint(1 << 1)
const FUSE_IOCTL_RETRY = Cuint(1 << 2)
const FUSE_IOCTL_DIR = Cuint(1 << 4)
const FUSE_IOCTL_MAX_IOV = 256


# dummy function - should never by actually called
noop(args...) = UV_ENOTSUP
const REGISTERED = Function[noop for i = 1:F_SIZE]
regops() = REGISTERED
# utility functions
function fcallback(which::Int, args...)
    regops()[which](args...)
end

function register(which::Int, f::Function)
    regops()[which] = f
end
function register(which::Symbol, f::Function)
    index = findfirst(isequal(which), fieldnames(FuseLowlevelOps))
    register(index, f)
end
register(f::Function) = register(nameof(f), f)

function FuseLowlevelOps(all::FuseLowlevelOps, reg::Vector{Function})
    FuseLowlevelOps(filter_ops(all, reg)...)
end
function filter_ops(all::Vector, reg::Vector{Function})
    [reg[i] == noop ? C_NULL : all[i] for i in eachindex(all)]
end

function filter_ops(fs::Module)
    all = ALL_FLO()
    res = fill(C_NULL, length(fieldnames(FuseLowlevelOps)))
    ro = regops()
    for (i, f) in enumerate(fieldnames(FuseLowlevelOps))
        if (c = getp(fs, f, noop)) != noop
            res[i] = all[i]
            ro[i] = c
        end     
    end
    res
end

function getp(m, f::Symbol, def)
    try
        getproperty(m, f)
    catch
        def
    end
end

function create_args(CMD::String, arg::AbstractVector{String})
    argc = length(arg)
    data = create_bytes(FuseArgs, argc + 2)
    args = CStructGuided{FuseArgs}(data)
    argv = args.argv
    args.argc = argc + 1
    argv[1] = CMD
    for i = 1:argc
        argv[i+1] = arg[i]
    end
    args
end

function main_loop(args::AbstractVector{String}, fs::Module)

    fargs = create_args("command", args)
    opts = fuse_parse_cmdline(fargs)

    callbacks = filter_ops(fs)

    se = ccall((:fuse_session_new, :libfuse3), Ptr{Nothing},
        (Ptr{FuseArgs}, Ptr{CFu}, Cint, Ptr{Nothing}),
        fargs, callbacks, length(callbacks), C_NULL)

    se == C_NULL && throw(ArgumentError("fuse_session_new failed"))

    rc = ccall((:fuse_session_mount, :libfuse3), Cint, (Ptr{Nothing}, Cstring), se, opts.mountpoint)
    rc != 0 && throw(ArgumentError("fuse_session_mount failed"))

    rc = ccall((:fuse_session_loop, :libfuse3), Cint, (Ptr{Nothing},), se)
    rc != 0 && throw(ArgumentError("fuse_session_loop failed"))

    ccall((:fuse_session_unmount, :libfuse3), Cvoid, (Ptr{Nothing},), se)
    ccall((:fuse_session_destroy, :libfuse3), Cvoid, (Ptr{Nothing},), se)
end


function fuse_parse_cmdline(args::CStructAccess{FuseArgs})
    opts = create_bytes(FuseCmdlineOpts)
    popts = pointer_from_vector(opts)
    ccall((:fuse_parse_cmdline, :libfuse3), Cint, (Ptr{FuseArgs}, Ptr{UInt8}), args, popts)
    CStructGuided{FuseCmdlineOpts}(opts)
end

function log(args...)
    flush(stderr)
    println(stderr, args...)
end


# Base.unsafe_convert(::Type{Ptr{FuseReq}}, cs::FuseReq) where T = Ptr{FuseReq}(cs.pointer)
