module ExampleFs
using ..FuseApi

using CStructures: CStruct, CStructGuarded, CVector, Cserialize

import Base: open, read, write, unlink, rename, readdir

using Base.Filesystem
import Base.Filesystem: S_IFDIR, S_IFREG, S_IFCHR, S_IFBLK, S_IFIFO, S_IFLNK, S_IFSOCK, S_IFMT
import Base.Filesystem: S_IRWXU, S_IRWXG, S_IRWXO
import Base.Filesystem: S_IRUSR, S_IRGRP, S_IROTH
import Base.Filesystem: S_IWUSR, S_IWGRP, S_IWOTH
import Base.Filesystem: S_IXUSR, S_IXGRP, S_IXOTH
import Base.Filesystem: S_ISUID, S_ISGID, S_ISVTX

import Base: UV_ENOENT, UV_ENOTDIR, UV_EEXIST, UV_ENOTEMPTY, UV_ENAMETOOLONG, UV_ERANGE
const UV_ENODATA = -61 # missing in Base

const X_UGO = S_IRWXU | S_IRWXG | S_IRWXO
const X_NOX = X_UGO & ~((S_IXUSR | S_IXGRP | S_IXOTH) & X_UGO)

const DIR1 = "."
const DIR2 = ".."

const PATH_MAX = 4096

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

struct FilesystemData
    inodes::Dict{FuseIno, Inode}
    data::Dict{FuseIno, Vector{UInt8}}
    data_dir::Dict{FuseIno, Vector{Direntry}}
    xattr::Dict{FuseIno, Vector{Tuple{String,Vector{UInt8}}}}
    FilesystemData(root) = new(Dict(FUSE_INO_ROOT => root), Dict(), Dict(), Dict())
end

get_inode(fs::FilesystemData, ino::FuseIno) = get(fs.inodes, ino, nothing)
has_inode(fs::FilesystemData, ino::FuseIno) = haskey(fs.inodes, ino)
next_ino(fs::FilesystemData) = maximum(keys(fs.inodes)) + 1
push_inode!(fs::FilesystemData, inode::Pair{FuseIno,Inode}) = push!(fs.inodes, inode)

get_data(fs::FilesystemData, ino::FuseIno) = get(fs.data, ino) do; UInt8[] end
get_data!(fs::FilesystemData, ino::FuseIno) = get!(fs.data, ino) do; UInt8[] end
set_data!(fs::FilesystemData, ino::FuseIno, v) = setindex!(fs.data, ino, v)
has_data(fs::FilesystemData, ino::FuseIno) = haskey(fs.data, ino)
push_data!(fs::FilesystemData, inode::Pair{FuseIno}) = push!(fs.data, inode)
delete_data!(fs::FilesystemData, inode::Pair{FuseIno}) = delete!(fs.data, inode)

function lookup_ino(fs::FilesystemData, parent::Integer, name::AbstractString)
    haskey(fs.data_dir, parent) || return 0
    direntries = fs.data_dir[parent]
    k = findfirst(de -> de.name == name, direntries)
    k === nothing ? 0 : direntries[k].ino
end
get_direntries(fs::FilesystemData, ino::Integer) = get(fs.data_dir, ino) do; Direntry[] end
get_direntries!(fs::FilesystemData, ino::Integer) = get!(fs.data_dir, ino) do; Direntry[] end

get_xattr(fs::FilesystemData, ino::Integer) = get(fs.xattr, ino) do; emptyxvec() end
set_xattr!(fs::FilesystemData, ino::Integer, vec) = fs.xattr[ino] = vec

function destroy_ino!(fs::FilesystemData, ino::FuseIno)
    delete!(fs.inodes, ino)
    delete!(fs.data, ino)
    delete!(fs.data_dir, ino)
    delete!(fs.xattr, ino)
    nothing
end


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
function status(fs::FilesystemData, ino::FuseIno)
    status(get_inode(fs, ino))
end

function example(fs::FilesystemData, parent::Integer, name::String, data=nothing)
    inode = do_create(fs, FuseIno(parent), name, S_IFREG | X_UGO, 0, 0)
    if data !== nothing
        d =  convert(Vector{UInt8}, data)
        inode.size = length(d)
        push_data!(fs, inode.ino => d)
    end
end

# implementation of callback functions

export init
function init(userdata::Any, conn::CStruct{FuseConnInfo})
    #println("init userdata = '$userdata'")
    #println("init conninfo = $conn")
end

export destroy
function destroy(userdata::Any)
    #println("destroy userdata = '$userdata'")
end

export lookup
function lookup(fs::Any, req::FuseReq, parent::FuseIno, name::String)
    entry = do_lookup(fs, req, parent, name)
    entry isa Number ? entry : fuse_reply_entry(req, entry)
end

function find_direntry(fs::FilesystemData, parent::Integer, name::AbstractString)
    parent = FuseIno(parent)
    has_inode(fs, parent) || return UV_ENOENT
    is_directory(fs.inodes[parent]) || return UV_ENOTDIR
    ino = lookup_ino(fs, parent, name)
    ino == 0 ? UV_ENOENT : ino
end

function do_lookup(fs::FilesystemData, req::FuseReq, parent::FuseIno, name::String)
    ino = find_direntry(fs, parent, name)
    ino <= 0 && return ino
    sta = status(fs, ino)
    entry = CStructGuarded(FuseEntryParam, (ino=ino, attr=sta))
    entry.attr_timeout = 0.0
    entry.entry_timeout = 1e19
    entry
end

export forget
function forget(fs::Any, req::FuseReq, ino::FuseIno, count::Integer)
    fuse_reply_none(req)
end

export getattr
function getattr(fs::Any, req::FuseReq, ino::FuseIno, ::CStruct{FuseFileInfo})
    has_inode(fs, ino) || return UV_ENOENT
    attr = status(fs, ino)
    attr_timeout = 10.0
    fuse_reply_attr(req, attr, attr_timeout)
end

export setattr
function setattr(fs::Any, req::FuseReq, ino::FuseIno, st::CStruct{Cstat}, to_set::Integer, fi::CStruct{FuseFileInfo})
    has_inode(fs, ino) || return UV_ENOENT
    inode = get_inode(fs, ino)::Inode
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
    getattr(fs, req, ino, fi)
end

export opendir
function opendir(fs::Any, req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_open(req, fi)
end

export releasedir
function releasedir(fs::Any, req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_err(req, 0)
end

export readdir
function readdir(fs::Any, req::FuseReq, ino::FuseIno, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    buf = Vector{UInt8}(undef, size)
    dir = get_inode(fs, ino)::Inode
    is_directory(dir) || return UV_ENOTDIR
    i = off + 1
    p = 1
    des = get_direntries(fs, ino)
    n = length(des)
    rem = size
    while i <= n + 2
        if i <= 2
            st = status(dir)
            name = i == 1 ? DIR1 : DIR2
        else
            de = des[i-2]
            st = status(fs, de.ino)
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

function do_create(fs::FilesystemData, parent::FuseIno, name::String, mode::Integer, uid::Integer, gid::Integer)
    dir = get_inode(fs, parent)::Inode
    is_directory(dir) || return UV_ENOTDIR
    lookup_ino(fs, parent, name) == 0 || return UV_EEXIST
    ino = next_ino(fs)
    inode = Inode(ino, mode, 1, 0, uid, gid)
    push_inode!(fs, ino => inode)
    direntries = get_direntries!(fs, parent)
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode
end

export create
function create(fs::Any, req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, fi::CStruct{FuseFileInfo})
    ctx = fuse_req_ctx(req)
    uid = ctx.uid
    gid = ctx.gid
    umask = ctx.umask
    mode = mode & ~umask | mode & ~X_UGO
    do_create(fs, parent, name, mode, uid, gid)
    entry = do_lookup(fs, req, parent, name)
    fuse_reply_create(req, entry, fi)
end

export open
function open(fs::Any, req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    inode = get_inode(fs, ino)::Inode
    if is_regular(inode) && fi.flags & JL_O_TRUNC != 0
        inode.size = 0
        delete_data!(fs, ino)
    end
    fuse_reply_open(req, fi)
end

export read
function read(fs::Any, req::FuseReq, ino::FuseIno, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    has_inode(fs, ino) || return UV_ENOENT
    inode = get_inode(fs, ino)::Inode
    is_directory(inode) && return UV_ENOENT
    data = get_data(fs, ino)
    sz = max(min(length(data) - off, size), 0)
    bufv = CStructGuarded{FuseBufvec}(Cserialize(FuseBufvec, (count=1, buf=[(size=sz, mem = data)])))
    if sz > 0
        touch(inode, T_ATIME)
    end
    fuse_reply_data(req, bufv, FuseBufCopyFlags(0))
end

export write
function write(fs::Any, req::FuseReq, ino::FuseIno, cvec::CVector{UInt8}, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    inode = get_inode(fs, ino)::Inode
    is_directory(inode) && return UV_ENOENT
    data = get_data!(fs, ino)
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

export link
function link(fs::Any, req::FuseReq, ino::FuseIno, newparent::FuseIno, name::String)
    inode = get_inode(fs, ino)::Inode
    is_directory(inode) && return UV_EPERM
    dir = get_inode(fs, newparent)::Inode
    is_directory(dir) || return UV_ENOTDIR
    lookup_ino(fs, newparent, name) == 0 || return UV_EEXIST
    direntries = get_direntries!(fs, newparent)
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode.nlink += 1
    entry = do_lookup(fs, req, newparent, name)
    fuse_reply_entry(req, entry)
end

export unlink
function unlink(fs::Any, req::FuseReq, parent::FuseIno, name::String)
    ino = find_direntry(fs, parent, name)
    ino <= 0 && return ino
    direntries = get_direntries(fs, parent)
    deleteat!(direntries, findall(de -> de.name == name, direntries))
    dir = get_inode(fs, parent)::Inode
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    inode = get_inode(fs, ino)::Inode
    inode.nlink -= 1
    if inode.nlink <= 0
        destroy_ino!(fs, ino)
    else
        touch(inode, T_CTIME)
    end
    return fuse_reply_err(req, 0)
end

export rename
function rename(fs::Any, req::FuseReq, parent::FuseIno, name::String, newparent::FuseIno, newname::String, flags::Integer)
    # println("rename($parent/$name => $newparent/$newname)")
    if parent == newparent && name == newname
        return fuse_reply_err(req, 0)
    end
    dir = get_inode(fs, parent)::Inode
    dirnew = parent == newparent ? dir : get_inode(fs, newparent)::Inode
    ino = lookup_ino(fs, parent, name)
    ino == 0 && return UV_ENOENT
    newino = lookup_ino(fs, newparent, newname)
    newino == 0 && flags == RENAME_EXCHANGE && return UV_ENOENT
    newino != 0 && flags == RENAME_NOREPLACE && return UV_EEXIST
    des = get_direntries(fs, parent)
    desnew = parent == newparent ? des : get_direntries!(fs, newparent)
    k = findfirst(de -> de.name == name, des)::Integer
    de = des[k]
    knew = newino == 0 ? 0 : findfirst(de -> de.name == newname, desnew)::Integer

    if flags == RENAME_EXCHANGE
        den = desnew[knew]
        des[k] = Direntry(de.ino, den.name)
        desnew[knew] = Direntry(den.ino, de.name)
    else
        if parent == newparent
            des[k] = Direntry(de.ino, newname)
        else
            push!(desnew, name == newname ? des[k] : Direntry(de.ino, newname))
            deleteat!(des, k)
        end
        if knew != 0 # && flags != RENAME_NOREPLACE 
            deleteat!(desnew, knew)
        end
    end

    touchdir(dir, des, T_MTIME | T_CTIME)
    if parent != newparent
        touchdir(dirnew, desnew, T_MTIME | T_CTIME)
    end
    fuse_reply_err(req, 0)
end

export mkdir
function mkdir(fs::Any, req::FuseReq, parent::FuseIno, name::String, mode::FuseMode)
    ctx = fuse_req_ctx(req)
    uid = ctx.uid
    gid = ctx.gid
    umask = ctx.umask
    mode = mode & X_UGO & ~umask | mode & (S_ISUID | S_ISGID | S_ISVTX) | S_IFDIR
    do_create(fs, parent, name, mode, uid, gid)
    entry = do_lookup(fs, req, parent, name)
    fuse_reply_entry(req, entry)
end

export rmdir
function rmdir(fs::Any, req::FuseReq, parent::FuseIno, name::String)
    ino = find_direntry(fs, parent, name)
    ino <= 0 && return ino
    !isempty(get_direntries(fs, ino)) && return UV_ENOTEMPTY

    direntries = get_direntries(fs, parent)
    deleteat!(direntries, findall(de -> de.name == name, direntries))
    dir = get_inode(fs, parent)::Inode
    touchdir(dir, direntries, T_MTIME | T_CTIME)
    return fuse_reply_err(req, 0)
end

export symlink
function symlink(fs::Any, req::FuseReq, link::String, parent::FuseIno, name::String)
    # println("symlink($parent/$name => $link)")
    n = length(link)
    0 < n < PATH_MAX || return UV_ENAMETOOLONG
    ctx = fuse_req_ctx(req)
    uid = ctx.uid
    gid = ctx.gid
    mode = X_UGO | S_IFLNK
    inode = do_create(fs, parent, name, mode, uid, gid)
    inode.size = n
    vlink = collect(codeunits(link))
    set_data!(fs, inode.ino, push!(vlink, 0x00))
    entry = do_lookup(fs, req, parent, name)
    fuse_reply_entry(req, entry)
end

export readlink
function readlink(fs::Any, req::FuseReq, ino::FuseIno)
    link = get_data(fs, ino)
    fuse_reply_readlink(req, link)
end

export setxattr
function setxattr(fs::Any, req::FuseReq, ino::FuseIno, name::String, value::Vector{UInt8}, flags::Integer)
    vec = get_xattr(fs, ino)
    k = findfirst(x->x[1] == name, vec)
    hk = k === nothing
    flags == XATTR_CREATE && hk && return UV_EEXIST
    flags == XATTR_REPLACE && !hk && return UV_ENODATA
    if k === nothing
        set_xattr!(fs, ino, push!(vec, (name, value)))
    else
        vec[k] = (name, value)
    end
    fuse_reply_err(req, 0)
end

export getxattr
function getxattr(fs::Any, req::FuseReq, ino::FuseIno, name::String, size::Integer)
    vec = get_xattr(fs, ino)
    k = findfirst(x->x[1] == name, vec)
    k === nothing && return UV_ENODATA
    val = vec[k][2]
    #println("getxattr($name) = $val")
    bsize = sizeof(val)
    if size == 0
        fuse_reply_xattr(req, bsize)
    else
        bsize > size && return UV_ERANGE
        fuse_reply_buf(req, val, bsize)
    end
end

export removexattr
function removexattr(fs::Any, req::FuseReq, ino::FuseIno, name::String)
    vec = get_xattr(fs, ino)
    k = findfirst(x->x[1] == name, vec)
    if k !== nothing
        deleteat!(vec, k)
    end
    fuse_reply_err(req, 0)
end

export listxattr
function listxattr(fs::Any, req::FuseReq, ino::FuseIno, size::Integer)
    str = join([t[1] for t in get_xattr(fs, ino)], '\0')
    val = collect(codeunits(str))
    !isempty(val) && push!(val, 0x0)
    #println("listxattr($ino, $size); val = $val")
    bsize = sizeof(val)
    if size == 0
        fuse_reply_xattr(req, bsize)
    else
        bsize > size && return UV_ERANGE
        fuse_reply_buf(req, val, bsize)
    end
end


# utility functions

function touchdir(dir::Inode, direntries, mode)
    dir.size = length(direntries)
    touch(dir, mode)
end
emptyxvec() = Tuple{String,Vector{UInt8}}[]

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


args = ["mountpoint", "-s", "-d", "-h", "-V", "-f" , "-o", "clone_fd", "-o", "max_idle_threads=5"]

const FS = FilesystemData(Inode(FUSE_INO_ROOT, S_IFDIR | X_UGO, 1, 0, 0, 0))
example(FS, 1, "xxx", codeunits("hello world 4711!\n"))

using Base.Threads

bg() = @spawn main_loop($args, @__MODULE__, FS) 
fg() = main_loop(args, @__MODULE__, FS)

end # module ExampleFs