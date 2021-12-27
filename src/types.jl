
export FuseLowlevelOps
export FUSE_INO_ROOT, RENAME_NOREPLACE, RENAME_EXCHANGE
export FuseConnInfo, FuseFileInfo, FuseEntryParam, FuseCmdlineArgs, FuseCmdlineOpts, FuseReq, FuseIno, FuseMode
export FuseBufvec, FuseBuf, FuseBufFlags, FuseBufCopyFlags
export Cstat, Cflock, Timespec

export FUSE_SET_ATTR_MODE, FUSE_SET_ATTR_UID, FUSE_SET_ATTR_GID, FUSE_SET_ATTR_SIZE
export FUSE_SET_ATTR_ATIME, FUSE_SET_ATTR_MTIME, FUSE_SET_ATTR_ATIME_NOW, FUSE_SET_ATTR_MTIME_NOW, FUSE_SET_ATTR_CTIME

const CFu = Ptr{Cvoid}

"""
    FuseLoopConfig <: Layout

Layout template as input for `fuse_session_loop_mt`.

Named `struct fuse_loop_config` in `libfuse3`.
"""
struct FuseLoopConfig <: Layout
    clone_fd::Cint
    max_idle_threads::Cuint
end

"""
    FuseCmdlineArgs <: Layout

Layout template for commandline arguments as to be passed to fuse_parse_cmdline

The length of vector pointed to by `argv` is stored in field `argc`.
Field `allocated` must be set to `0`, if the data is Julia generated.

If generated by Julia, use `CStructGuarded{FuseCmdlineArgs}`.
"""
struct FuseCmdlineArgs <: Layout
    argc::Cint
    argv::Ptr{LVarVector{Cstring, (x) -> x.argc + 1}}
    allocated::Cint
end

"""
    FuseCmdlineOpts <: Layout

Layout template for output argument of `fuse_parse_cmdline`.

Has to be allocated by Julia caller, by `CStructGuarded{FuseCmdlineOpts}`.

Field `mountpoint` has to be copied immediately ofter the call, because
the `*char` pointer stored in there is unsafe.
"""
struct FuseCmdlineOpts <: Layout
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

"""
    FuseSession <: Layout

Opaque object as returned by `fuse_session_new` and used by subsequent
fuse session management calls. (see `main_loop`)
"""
struct FuseSession <: Layout
end

"""
    FuseLowlevelOps

This structure mainly defines the names and sequence of callback functions,
which can be used by the `libfuse3` lowlevel interface.

Named `struct fuse_lowlevel_ops` in `Fuse3` library.
"""
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
const Cuint64_t = UInt64
const Cpid_t = Cint
const Cfsblkcnt_t = UInt64
const Cfsfilcnt_t = UInt64

const FUSE_INO_ROOT = FuseIno(1)

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

Opaque structure to identify the request. Contains the pointer as obtained by fuselib.

All typical fuse callback functions use that as their first argument.
"""
struct FuseReq
    pointer::Ptr{Nothing}
end

"""
    Timespec <: Layout

C-structure as contained in `Cstat` (`struct stat`).
"""
struct Timespec <: Layout
    seconds::Int64
    nanoseconds::Int64
end

"""
    FuseCtx <: Layout

C-structure returned by `fuse_req_ctx(req)` containg `uid`, `gid`, `pid`, and `umask`
of the process, which is responsible for the request.

The data is only valid while the request `req` is being processed within one of the
callback bunctions.
"""
struct FuseCtx <: Layout
    uid::Cuid_t
    gid::Cgid_t
    pid::Cpid_t
    umask::FuseMode
end

"""
    Cstat <: Layout

C-structure containing inode data. Named `struct stat` in std C library.
"""
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

"""
    FuseEntryParam <: Layout

Fuse wrapper type for a `struct stat`, adding some extra fields.
Contains an embedded field `attr::Cstat` with `struct stat` data. 
"""
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

"""
    FuseConnInfo <: Layout

"""
struct FuseConnInfo <: Layout
    proto_major::Cuint
    proto_minor::Cuint
    max_write::Cuint
    max_read::Cuint
    max_readahead::Cuint
    capable::Cuint
    want::Cuint
    max_background::Cuint
    congestion_threshold::Cuint
    time_gran::Cuint
    # reserved::LFixedVector{Cuint,22}
end

# bit masks for 2nd field of FuseFileInfo
const FUSE_FI_WRITEPAGE = Cuint(1 << 0)
const FUSE_FI_DIRECT_IO = Cuint(1 << 1)
const FUSE_FI_KEEP_CACHE = Cuint(1 << 2)
const FUSE_FI_FLUSH = Cuint(1 << 3)
const FUSE_FI_NONSEEKABLE = Cuint(1 << 4)
const FUSE_FI_CACHE_READDIR = Cuint(1 << 5)

"""
    FuseFileInfo <: Layout

Layout of C-structure used by many fuse callbacks.

The C-structure is allocated and populated by the `libfuse3` C-library
and passed as a pointer to the callback functions as an argument
`fi::Ptr{FuseFileInfo}`, which is made accessible to Julia by
the `CStruct(fi)` conversion.
"""
struct FuseFileInfo <: Layout
    flags::Cint
    bits::Cuint
    fh::UInt64
    lock_owner::UInt64
    poll_events::UInt32
end

"""
    Cflock <: Layout

C-structure for `flock` callback. Named `struct flock` in std C library.
"""
struct Cflock <: Layout
    type::Cshort
    whence::Cshort
    start::Coff64_t
    len::Coff64_t
    pid::Cpid_t
end

"""
    Ciovec <: Layout

C-structure for `ioctl` callback. Named `struct iovec` in std C library.
"""
struct Ciovec <: Layout
    base::Ptr{Cvoid}
    len::Csize_t
end

"""
    Cstatfs <: Layout

C-structure for `statfs` callback. Named `struct statfs` in std C library.
"""
struct Cstatvfs <: Layout
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

struct FusePollHandle <: Layout
end

"""
    FuseBuf <: Layout

Flexible size buffer containing a pointer to variable size data and a size.

The buffer object itself has fixed size.
Used in conjunction with `FuseBufvec`.
"""
struct FuseBuf <: Layout
    size::Csize_t
    flags::FuseBufFlags
    mem::Ptr{LVarVector{UInt8, (x) -> x.size}}
    fd::Cint
    pos::Coff_t
end

"""
    FuseBufvec <: Layout

Variable sized vector of buffers of type `FuseBuf`.
"""
struct FuseBufvec <: Layout
    count::Csize_t
    idx::Csize_t
    off::Csize_t
    buf::LVarVector{FuseBuf, (x) -> x.count}
end
struct FuseForgetData
end

# used for setattr function
const FUSE_SET_ATTR_MODE      = Cuint(1 << 0)
const FUSE_SET_ATTR_UID       = Cuint(1 << 1)
const FUSE_SET_ATTR_GID       = Cuint(1 << 2)
const FUSE_SET_ATTR_SIZE      = Cuint(1 << 3)
const FUSE_SET_ATTR_ATIME     = Cuint(1 << 4)
const FUSE_SET_ATTR_MTIME     = Cuint(1 << 5)
const FUSE_SET_ATTR_ATIME_NOW = Cuint(1 << 7)
const FUSE_SET_ATTR_MTIME_NOW = Cuint(1 << 8)
const FUSE_SET_ATTR_CTIME     = Cuint(1 << 10)

# used for ioctl function
const FUSE_IOCTL_COMPAT = Cuint(1 << 0)
const FUSE_IOCTL_UNRESTRICTED = Cuint(1 << 1)
const FUSE_IOCTL_RETRY = Cuint(1 << 2)
const FUSE_IOCTL_DIR = Cuint(1 << 4)
const FUSE_IOCTL_MAX_IOV = 256

# for replace function
const RENAME_NOREPLACE = (1 << 0)
const RENAME_EXCHANGE = (1 << 1)
