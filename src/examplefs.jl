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


struct Direntry
    ino::FuseIno
    name::String
end

mutable struct Inode
    ino::FuseIno
    mode::FuseMode
    nlink::Int64
    size::UInt64
    atime::Timespec
    mtime::Timespec
    ctime::Timespec
    function Inode(ino, mode, nlink, size)
        t = timespec_now()
        new(ino, mode, nlink, size, t, t, t)
    end
end

is_directory(inode::Inode) = inode.mode & S_IFMT == S_IFDIR
is_regular(inode::Inode) = inode.mode & S_IFMT == S_IFREG


function status(inode::Inode)
    st = CStructGuarded(Cstat)
    st.ino = inode.ino
    st.mode = inode.mode
    st.nlink = inode.nlink
    st.uid = 10003
    st.gid = 10000
    st.atime = inode.atime
    st.mtime = inode.mtime
    st.ctime = inode.ctime
    st.size = inode.size
    st
end

function status(ino::FuseIno)
    status(get(INODES, ino, nothing))
end

const ROOT = Inode(FUSE_INO_ROOT, S_IFDIR | X_UGO, 1, 0)
const INODES = Dict{FuseIno, Inode}(FUSE_INO_ROOT => ROOT)
const DATA = Dict{FuseIno, Vector{UInt8}}()
const DIR_DATA = Dict{FuseIno, Vector{Direntry}}()

function example(parent, name, data=nothing)
    file = do_create(parent, name, S_IFREG | X_UGO)
    if data !== nothing
        d =  convert(Vector{UInt8}, data)
        file.size = length(d)
        push!(DATA, file.ino => d)
    end
end

function lookup(req::FuseReq, parent::FuseIno, name::String)
    println("lookup(req, $parent, $name) called")
    entry = do_lookup(req, parent, name)
    entry isa Number ? entry : fuse_reply_entry(req, entry)
end

function find_direntry(parent::Integer, name::AbstractString)
    parent = FuseIno(parent)
    haskey(INODES, parent) || return UV_ENOENT
    dir = INODES[parent]
    is_directory(dir) || return UV_ENOTDIR
    haskey(DIR_DATA, parent) || return UV_ENOENT
    direntries = DIR_DATA[parent]
    k = findfirst(de -> de.name == name, direntries)
    k === nothing && return UV_ENOENT
    direntries[k]
end

function do_lookup(req::FuseReq, parent::FuseIno, name::String)
    de = find_direntry(parent, name)
    de isa Number && return de
    sta = status(de.ino)
    entry = CStructGuarded(FuseEntryParam, (ino=de.ino, attr=sta))
    entry.attr_timeout = 0.0
    entry.entry_timeout = 1e19
    entry
end

function getattr(req::FuseReq, ino::FuseIno, ::CStruct{FuseFileInfo})
    println("getattr(req, $ino, ...) called")
    haskey(INODES, ino) || return UV_ENOENT
    en = INODES[ino]
    attr = status(en)
    attr_timeout = 10.0
    fuse_reply_attr(req, attr, attr_timeout)
end

function opendir(req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_open(req, fi)
end

function releasedir(req::FuseReq, ino::FuseIno, fi::CStruct{FuseFileInfo})
    fuse_reply_err(req, 0)
end

function readdir(req::FuseReq, ino::FuseIno, size::Integer, off::Integer, ::CStruct{FuseFileInfo})
    println("readdir(req, $ino, $size, $off, fi) called")
    buf = Vector{UInt8}(undef, size)
    dir = INODES[ino]
    is_directory(dir) || return UV_ENOTDIR
    i = off + 1
    p = 1
    des = get(DIR_DATA, ino) do; Direntry[] end
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
        println("add_direntry($(name), $i) = $entsize called")
        if entsize > rem
            break
        end
        p += entsize
        rem -= entsize
        i += 1
    end
    fuse_reply_buf(req, buf, size - rem)
end

function do_create(parent::Integer, name::String, mode::Integer)
    dir = INODES[parent]
    is_directory(dir) || return UV_ENOTDIR
    find_direntry(parent, name) == UV_ENOENT || return UV_EEXIST
    ino = maximum(keys(INODES)) + 1
    inode = Inode(ino, mode, 1, 0)
    push!(INODES, ino => inode)
    direntries = get!(DIR_DATA, parent) do; Direntry[] end
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries)
    inode
end

function create(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, fi::CStruct{FuseFileInfo})
    do_create(parent, name, mode)
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

function read(req::FuseReq, ino::FuseIno, size::Integer, off::Integer, fi::CStruct{FuseFileInfo})
    save_fi(fi)
    haskey(INODES, ino) || return UV_ENOENT
    inode = INODES[ino]
    is_directory(inode) && return UV_ENOENT
    data = get(DATA, ino) do; UInt8[] end
    sz = max(min(length(data) - off, size), 0)
    bufv = CStructGuarded{FuseBufvec}(Cserialize(FuseBufvec, (count=1, buf=[(size=sz, mem = data)])))
    if sz > 0
        toucha(inode)
    end
    fuse_reply_data(req, bufv, FuseBufCopyFlags(0))
end

const LASTFI = Any[]

function write(req::FuseReq, ino::FuseIno, cvec::CVector{UInt8}, size::Integer, off::Integer, fi::CStruct{FuseFileInfo})
    save_fi(fi)
    inode = INODES[ino]
    is_directory(inode) && return UV_ENOENT
    data = get!(DATA, ino, UInt8[])
    total = off + size
    if total > length(data)
        resize!(data, total)
        inode.size = total
        for i = length(data)+1:off
            data[i] = 0
        end
    end
    for i = 1:size
        data[off+i] = cvec[i]
    end
    if size > 0
        touch(inode)
    end
    fuse_reply_write(req, size)
end

function link(req::FuseReq, ino::FuseIno, newparent::FuseIno, name::String)
    inode = INODES[ino]
    is_directory(inode) && return UV_EPERM
    dir = INODES[newparent]
    is_directory(dir) || return UV_ENOTDIR
    find_direntry(newparent, name) == UV_ENOENT || return UV_EEXIST
    direntries = get!(DIR_DATA, newparent) do; Direntry[] end
    push!(direntries, Direntry(ino, name))
    touchdir(dir, direntries)
    inode.nlink += 1
    entry = do_lookup(req, newparent, name)
    fuse_reply_entry(req, entry)
end

function unlink(req::FuseReq, parent::FuseIno, name::String)
    de = find_direntry(parent, name)
    de isa Number && return de
    direntries = DIR_DATA[parent]
    k = findfirst(de -> de.name == name, direntries)
    deleteat!(direntries, k)
    dir = INODES[parent]
    touchdir(dir, direntries)
    inode = INODES[de.ino]
    inode.nlink -= 1
    if inode.nlink <= 0
        delete!(INODES, de.ino)
    end
    return fuse_reply_err(req, 0)
end

function touchdir(dir, direntries)
    dir.size = length(direntries)
    touch(dir)
end

function touch(inode::Inode)
    t = timespec_now()
    inode.mtime = t
    inode.ctime = t
end
function toucha(inode::Inode)
    t = timespec_now()
    inode.atime = t
end


function save_fi(fi::CStructAccess{T}) where T
    u = collect(unsafe_load(Ptr{NTuple{sizeof(T),UInt8}}(pointer(fi))))
    push!(LASTFI, u)
    nothing
end

example(1, "xxx", codeunits("hello world 4711!\n"))

args = ["mountpoint", "-d", "-h", "-V", "-f" , "-s", "-o", "clone_fd", "-o", "max_idle_threads=5"]

using Base.Threads

run() = @spawn main_loop($args, @__MODULE__)

end # module ExampleFs