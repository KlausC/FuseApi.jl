module ExampleFs
using ..FuseApi

using Base.Filesystem
import Base.Filesystem: S_IFDIR, S_IFREG, S_IFCHR, S_IFBLK, S_IFIFO, S_IFLNK, S_IFSOCK, S_IFMT
import Base.Filesystem: S_IRWXU, S_IRWXG, S_IRWXO
import Base.Filesystem: S_IRUSR, S_IRGRP, S_IROTH
import Base.Filesystem: S_IWUSR, S_IWGRP, S_IWOTH
import Base.Filesystem: S_IXUSR, S_IXGRP, S_IXOTH
import Base.Filesystem: S_ISUID, S_ISGID, S_ISVTX

import Base: UV_ENOENT, UV_ENOTDIR

const X_UGO = S_IRWXU | S_IRWXG | S_IRWXO
const X_NOX = X_UGO & ~((S_IXUSR | S_IXGRP | S_IXOTH) & X_UGO)

const DIR1 = "."
const DIR2 = ".."

const DEFAULT_MODE = S_IFREG | X_UGO

const T_ATIME = 0x0001
const T_MTIME = 0x0002
const T_CTIME = 0x0004

struct Direntry
    ino::FuseIno
    name::String
end

mutable struct Inode
    ino::FuseIno
    mode::FuseMode
    nlink::Int64
    size::UInt64
    uid::UInt32
    gid::UInt32
    atime::Timespec
    mtime::Timespec
    ctime::Timespec
    function Inode(ino, mode, nlink, size, uid, gid)
        t = timespec_now()
        new(ino, mode, nlink, size, uid, gid, t, t, t)
    end
end

is_directory(inode::Inode) = inode.mode & S_IFMT == S_IFDIR
is_regular(inode::Inode) = inode.mode & S_IFMT == S_IFREG


function status(inode::Inode)
    st = CStructGuarded(Cstat)
    st.ino = inode.ino
    st.mode = inode.mode
    st.nlink = inode.nlink
    st.uid = inode.uid
    st.gid = inode.gid
    st.size = inode.size
    st.atime = inode.atime
    st.mtime = inode.mtime
    st.ctime = inode.ctime
    st
end

function status(ino::FuseIno)
    status(get(INODES, ino, nothing))
end

const ROOT = Inode(FUSE_INO_ROOT, S_IFDIR | X_UGO, 1, 0, 0, 0)
const INODES = Dict{FuseIno, Inode}(FUSE_INO_ROOT => ROOT)
const DATA = Dict{FuseIno, Vector{UInt8}}()
const DIR_DATA = Dict{FuseIno, Vector{Direntry}}()

function example(parent, name, data=nothing)
    file = do_create(parent, name, S_IFREG | X_UGO, 0, 0)
    if data !== nothing
        d =  convert(Vector{UInt8}, data)
        file.size = length(d)
        push!(DATA, file.ino => d)
    end
end

function lookup(req::FuseReq, parent::FuseIno, name::String)
    entry = do_lookup(req, parent, name)
    entry isa Number ? entry : fuse_reply_entry(req, entry)
end

function find_direntry(parent::Integer, name::AbstractString)
    parent = FuseIno(parent)
    haskey(INODES, parent) || return UV_ENOENT
    is_directory(INODES[parent]) || return UV_ENOTDIR
    ino = lookup_ino(parent, name)
    ino == 0 ? UV_ENOENT : ino
end

function lookup_ino(parent::Integer, name::AbstractString)
    haskey(DIR_DATA, parent) || return 0
    direntries = DIR_DATA[parent]
    k = findfirst(de -> de.name == name, direntries)
    k === nothing ? 0 : direntries[k].ino
end

function do_lookup(req::FuseReq, parent::FuseIno, name::String)
    ino = find_direntry(parent, name)
    ino <= 0 && return ino
    sta = status(ino)
    entry = CStructGuarded(FuseEntryParam, (ino=ino, attr=sta))
    entry.attr_timeout = 0.0
    entry.entry_timeout = 1e19
    entry
end

function getattr(req::FuseReq, ino::FuseIno, ::CStruct{FuseFileInfo})
    haskey(INODES, ino) || return UV_ENOENT
    en = INODES[ino]
    attr = status(en)
    attr_timeout = 10.0
    fuse_reply_attr(req, attr, attr_timeout)
end

function setattr(req::FuseReq, ino::FuseIno, st::CStruct{Cstat}, to_set::Integer, fi::CStruct{FuseFileInfo})
    haskey(INODES, ino) || return UV_ENOENT
    inode = INODES[ino]
    resetsuid = false
    if to_set & FUSE_SET_ATTR_MODE != 0
        inode.mode = st.mode
    end 
    if to_set & FUSE_SET_ATTR_UID != 0
        resetsuid |= inode.uid != st.uid
        inode.uid = st.uid
    end
    if to_set & FUSE_SET_ATTR_GID != 0
        inode.gid = st.gid
    end
    if to_set & FUSE_SET_ATTR_SIZE != 0
        resetsuid |= inode.size != st.size
        inode.size = st.size
    end
    if to_set & FUSE_SET_ATTR_ATIME != 0
        inode.atime = st.atime
    end
    if to_set & FUSE_SET_ATTR_MTIME != 0
        inode.mtime = st.mtime
    end
    if to_set & (FUSE_SET_ATTR_ATIME_NOW | FUSE_SET_ATTR_MTIME_NOW) != 0
        t = timespec_now()
        if to_set & FUSE_SET_ATTR_ATIME_NOW != 0
            inode.atime = t
        end
        if to_set & FUSE_SET_ATTR_MTIME_NOW != 0
            inode.mtime = t
        end
    end
    if to_set & FUSE_SET_ATTR_CTIME != 0
        inode.ctime = st.ctime   
    end
    if resetsuid
        inode.mode &= ~(S_ISUID | S_ISGID)
    end
    getattr(req, ino, fi)
end

function opendir(req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_open(req, fi)
end

function releasedir(req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_err(req, 0)
end

function readdir(req::FuseReq, ino::FuseIno, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    buf = Vector{UInt8}(undef, size)
    dir = INODES[ino]
    is_directory(dir) || return UV_ENOTDIR
    i = off + 1
    p = 1
    des = get_direntries(ino)
    n = length(des)
    rem = size
    while i <= n + 2
        if i <= 2
            st = status(dir)
            name = "."^i
        else
            de = des[i-2]
            st = status(de.ino)
            name = de.name
        end
        entsize = fuse_add_direntry(req, view(buf, p:size), name, st, i)
        if entsize > rem
            break
        end
        p += entsize
        rem -= entsize
        i += 1
    end
    if p > 1
        touch(dir, T_ATIME)
    end
    fuse_reply_buf(req, buf, size - rem)
end

function do_create(parent::Integer, name::String, mode::Integer, uid::Integer, gid::Integer)
    dir = INODES[parent]
    is_directory(dir) || return UV_ENOTDIR
    lookup_ino(parent, name) == 0 || return UV_EEXIST
    ino = maximum(keys(INODES)) + 1
    inode = Inode(ino, mode, 1, 0, uid, gid)
    push!(INODES, ino => inode)
    direntries = get_direntries!(parent)
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode
end

function create(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, fi::CStruct{FuseFileInfo})
    ctx = fuse_req_ctx(req)
    uid = ctx.uid
    gid = ctx.gid
    umask = ctx.umask
    mode = mode & ~umask | mode & ~X_UGO
    do_create(parent, name, mode, uid, gid)
    entry = do_lookup(req, parent, name)
    fuse_reply_create(req, entry, fi)
end

function open(req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    inode = INODES[ino]
    if is_regular(inode) && fi.flags & JL_O_TRUNC != 0
        inode.size = 0
        delete!(DATA, ino)
    end
    fuse_reply_open(req, fi)
end

function read(req::FuseReq, ino::FuseIno, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    haskey(INODES, ino) || return UV_ENOENT
    inode = INODES[ino]
    is_directory(inode) && return UV_ENOENT
    data = get(DATA, ino) do; UInt8[] end
    sz = max(min(length(data) - off, size), 0)
    bufv = CStructGuarded{FuseBufvec}(Cserialize(FuseBufvec, (count=1, buf=[(size=sz, mem = data)])))
    if sz > 0
        touch(inode, T_ATIME)
    end
    fuse_reply_data(req, bufv, FuseBufCopyFlags(0))
end

const LASTFI = Any[]

function write(req::FuseReq, ino::FuseIno, cvec::CVector{UInt8}, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    inode = INODES[ino]
    is_directory(inode) && return UV_ENOENT
    data = get!(DATA, ino, UInt8[])
    total = off + size
    if total > length(data)
        resize!(data, total)
        for i = length(data)+1:off
            data[i] = 0
        end
    end
    for i = 1:size
        data[off+i] = cvec[i]
    end
    inode.size = length(data)
    if size > 0
        touch(inode, T_MTIME | T_CTIME)
        inode.mode &= ~(S_ISUID | S_ISGID)
    end
    fuse_reply_write(req, size)
end

function link(req::FuseReq, ino::FuseIno, newparent::FuseIno, name::String)
    inode = INODES[ino]
    is_directory(inode) && return UV_EPERM
    dir = INODES[newparent]
    is_directory(dir) || return UV_ENOTDIR
    lookup_ino(newparent, name) == 0 || return UV_EEXIST
    direntries = get_direntries!(newparent)
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode.nlink += 1
    entry = do_lookup(req, newparent, name)
    fuse_reply_entry(req, entry)
end

function unlink(req::FuseReq, parent::FuseIno, name::String)
    ino = find_direntry(parent, name)
    ino <= 0 && return ino
    direntries = get_direntries(parent)
    deleteat!(direntries, findall(de -> de.name == name, direntries))
    dir = INODES[parent]
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode = INODES[ino]
    inode.nlink -= 1
    if inode.nlink <= 0
        delete!(INODES, ino)
    else
        touch(inode, T_CTIME)
    end
    return fuse_reply_err(req, 0)
end

function rename(req::FuseReq, parent::FuseIno, name::String, newparent::FuseIno, newname::String, flags::Integer)

    if parent == newparent && name == newname
        return fuse_reply_err(req, 0)
    end
    dir = INODES[parent]
    dirnew = parent == newparent ? dir : INODES[newparent]
    ino = lookup_ino(parent, name)
    ino == 0 && return UV_ENOENT
    newino = lookup_ino(newparent, newname)
    newino == 0 && flags == RENAME_EXCHANGE && return UV_ENOENT
    newino != 0 && flags == RENAME_NOREPLACE && return UV_EEXIST
    des = get_direntries(parent)
    desnew = parent == newparent ? des : get_direntries!(newparent)
    k = findfirst(de -> de.name == name, des)::Integer
    de = des[k]
    knew = newino == 0 ? 0 : findfirst(de -> de.name == newname, desnew)::Integer

    if flags == RENAME_EXCHANGE
        den = desnew[knew]
        des[k] = Direntry(de.ino, den.name)
        desnew[knew] = Direntry(den.ino, de.name)
    else
        if knew != 0 # && flags != RENAME_NOREPLACE 
            deleteat!(desnew, knew)
        end
        if parent == newparent
            des[k] = Direntry(de.ino, newname)
        else
            push!(desnew, name == newname ? des[k] : Direntry(de.ino, newname))
            deleteat!(des, k)
        end
    end

    touchdir(dir, des, T_MTIME | T_CTIME)
    if parent != newparent
        touchdir(dirnew, desnew, T_MTIME | T_CTIME)
    end
    fuse_reply_err(req, 0)
end

# utility functions
get_direntries(ino::Integer) = get(DIR_DATA, ino) do; Direntry[] end
get_direntries!(ino::Integer) = get!(DIR_DATA, ino) do; Direntry[] end

function touchdir(dir::Inode, direntries, mode)
    dir.size = length(direntries)
    touch(dir, mode)
end

function Base.touch(inode::Inode, mode::UInt16)
    t = timespec_now()
    if mode & T_ATIME != 0
        inode.atime = t
    end
    if mode & T_MTIME != 0
        inode.mtime = t
    end
    if mode & T_CTIME != 0
        inode.ctime = t
    end
    t
end

example(1, "xxx", codeunits("hello world 4711!\n"))

args = ["mountpoint", "-d", "-h", "-V", "-f" , "-s", "-o", "clone_fd", "-o", "max_idle_threads=5"]

using Base.Threads

bg() = @spawn main_loop($args, @__MODULE__)

fg() = main_loop(args, @__MODULE__)

end # module ExampleFs