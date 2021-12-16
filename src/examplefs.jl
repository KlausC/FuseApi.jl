module ExampleFs
using ..FuseApi

using Base.Filesystem
import Base.Filesystem: S_IFDIR, S_IFREG, S_IFCHR, S_IFBLK, S_IFIFO, S_IFLNK, S_IFSOCK, S_IFMT
import Base.Filesystem: S_IRWXU, S_IRWXG, S_IRWXO
import Base.Filesystem: S_IRUSR, S_IRGRP, S_IROTH
import Base.Filesystem: S_IWUSR, S_IWGRP, S_IWOTH
import Base.Filesystem: S_IXUSR, S_IXGRP, S_IXOTH
import Base.Filesystem: S_ISUID, S_ISGID, S_ISVTX

const X_UGO = S_IRWXU | S_IRWXG | S_IRWXO
const X_NOX = X_UGO & ~((S_IXUSR | S_IXGRP | S_IXOTH) & X_UGO)

const DIR1 = "."
const DIR2 = ".."

const DEFAULT_MODE = S_IFREG | X_UGO


struct Direntry
    ino::FuseIno
    name::String
end

struct Inode
    ino::FuseIno
    mode::FuseMode
    nlink::Int64
end

abstract type Entity end

struct File <: Entity
    inode::Inode
    size::Int64
end

struct Directory <: Entity
    inode::Inode
    direntries::Vector{Direntry}
end

function Base.convert(::Type{Entity}, inode::Inode)
    etm = inode.mode & S_IFMT
    if etm == S_IFDIR
        Directory(inode, Direntry[])
    elseif etm == S_IFREG
        File(inode, 0)
    else
        File(inode, 0)
    end
end 

function status(e::File)
    st = status(e.inode)
    st.size = e.size
    st
end
function status(e::Directory)
    st = status(e.inode)
    st.size = length(e.direntries)
    st
end

function status(inode::Inode)
    st = CStructGuarded(Cstat)
    st.ino = inode.ino
    st.mode = inode.mode
    st.nlink = inode.nlink
    st.uid = 10003
    st.gid = 10000
    st
end

function status(ino::FuseIno)
    status(get(INODES, ino, nothing))
end

const ROOT = Directory(Inode(FUSE_INO_ROOT, S_IFDIR | X_UGO, 99), Direntry[])
const INODES = Dict{FuseIno, Entity}(FUSE_INO_ROOT => ROOT)

function example(parent, ino, name)
    FILE2 = File(Inode(ino, S_IFREG | X_UGO, 1), 100)
    push!(INODES, ino => FILE2)
    push!(INODES[parent].direntries, Direntry(ino, name))
end
example(1, 2, "xxx")

function lookup(req::FuseReq, parent::FuseIno, name::String)
    println("lookup(req, $parent, $name) called")
    entry = do_lookup(req, parent, name)
    entry isa Number ? entry : fuse_reply_entry(req, entry)
end

function do_lookup(req::FuseReq, parent::FuseIno, name::String)
    haskey(INODES, parent) || return Base.UV_ENOENT
    dir = INODES[parent]
    dir isa Directory || return Base.UV_NODIR
    k = findfirst(de -> de.name == name, dir.direntries)
    k === nothing && return Base.UV_ENOENT
    en = dir.direntries[k]
    sta = status(en.ino)
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
    haskey(INODES, ino) || return Base.UV_ENOENT
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
    dir isa Directory || return UV_ENODIR
    i = off + 1
    p = 1
    des = dir.direntries
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
    ino = maximum(keys(INODES)) + 1
    inode = Inode(ino, mode, 1)
    push!(INODES, ino => inode)
    dir = INODES[parent]
    push!(dir.direntries, Direntry(ino, name))
    entry = do_lookup(req, parent, name)
    fuse_reply_create(req, entry, fi)
end








args = ["mountpoint", "-d", "-h", "-V", "-f" , "-s", "-o", "clone_fd", "-o", "max_idle_threads=5"]

run() = main_loop(args, @__MODULE__)

end # module ExampleFs