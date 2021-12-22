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

const ROOT = Inode(FUSE_INO_ROOT, S_IFDIR | X_UGO, 1, 0, timespec_now(), timespec_now(), timespec_now())
const INODES = Dict{FuseIno, Inode}(FUSE_INO_ROOT => ROOT)
const DATA = Dict{FuseIno, Vector{UInt8}}()
const DIR_DATA = Dict{FuseIno, Vector{Direntry}}()

function example(parent, ino, name, data=nothing)
    t = timespec_now()
    file = Inode(ino, S_IFREG | X_UGO, 1, 0, t, t, t)
    push!(INODES, ino => file)
    direntries = get!(DIR_DATA, parent) do; Direntry[] end
    push!(direntries, Direntry(ino, name))
    INODES[parent].size = length(direntries)
    if data !== nothing
        d =  convert(Vector{UInt8}, data)
        file.size = length(d)
        push!(DATA, ino => d)
    end
end
example(1, 2, "xxx", codeunits("hello world 4711!"))

function lookup(req::FuseReq, parent::FuseIno, name::String)
    println("lookup(req, $parent, $name) called")
    entry = do_lookup(req, parent, name)
    entry isa Number ? entry : fuse_reply_entry(req, entry)
end

function do_lookup(req::FuseReq, parent::FuseIno, name::String)
    haskey(INODES, parent) || return UV_ENOENT
    dir = INODES[parent]
    is_directory(dir) || return UV_ENOTDIR
    haskey(DIR_DATA, parent) || return UV_ENOENT
    direntries = DIR_DATA[parent]
    k = findfirst(de -> de.name == name, direntries)
    k === nothing && return UV_ENOENT
    sta = status(direntries[k].ino)
    entry = CStructGuarded(FuseEntryParam)
    entry.ino = sta.ino
    entry.attr_timeout = 0.0
    entry.entry_timeout = 1e19
    st = entry.attr
    st.ino = sta.ino
    st.mode = sta.mode
    st.uid = sta.uid
    st.gid = sta.gid
    st.size = sta.size
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

function create(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, fi::CStruct{FuseFileInfo})
    dir = INODES[parent]
    is_directory(dir) || return UV_ENOTDIR
    ino = maximum(keys(INODES)) + 1
    t = timespec_now()
    inode = Inode(ino, mode, 1, 0, t, t, t)
    push!(INODES, ino => inode)
    direntries = get!(DIR_DATA, parent) do; Direntry[] end
    push!(direntries, Direntry(ino, name))
    dir.size = length(direntries)
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
    data = get(DATA, ino) do; UInt8[] end
    sz = max(min(length(data) - off, size), 0)
    bufv = CStructGuarded{FuseBufvec}(Cserialize(FuseBufvec, (count=1, buf=[(size=sz, mem = data)])))
    println("read(req, $ino, $size, $off) called, buffer = $bufv")
    if sz > 0
        inode = INODES[ino]
        inode.atime = timespec_now()
    end
    fuse_reply_data(req, bufv, FuseBufCopyFlags(0))
end

const LASTFI = Any[]

function write(req::FuseReq, ino::FuseIno, cvec::CVector{UInt8}, size::Integer, off::Integer, fi::CStruct{FuseFileInfo})
    save_fi(fi)
    inode = INODES[ino]
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
        t = timespec_now()
        inode.mtime = t
        inode.ctime = t
    end
    fuse_reply_write(req, size)
end

function save_fi(fi::CStructAccess{T}) where T
    u = collect(unsafe_load(Ptr{NTuple{sizeof(T),UInt8}}(pointer(fi))))
    push!(LASTFI, u)
    nothing
end


args = ["mountpoint", "-d", "-h", "-V", "-f" , "-s", "-o", "clone_fd", "-o", "max_idle_threads=5"]

run() = main_loop(args, @__MODULE__)

end # module ExampleFs