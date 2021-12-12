# C- entrypoints for all lowlevel callback functions

F_INIT = 1
function Cinit(userdata::Ptr{Nothing}, conn::Ptr{Nothing})
    try
        log("Cinit called")
        fcallback(F_INIT, userdata, CStruct{FuseConnInfo}(conn))
    finally
    end
end
F_DESTROY = 2
function Cdestroy(userdata::Ptr{Nothing})
    try
        fcallback(F_DESTROY, userdata)
    finally
    end
end
F_LOOKUP = 3
function Clookup(req::FuseReq, parent::FuseIno, name::Cstring)
    error = Base.UV_ENOTSUP
    name = unsafe_string(name)
    try
        log("Clookup called req=$req parent=$parent name=$name")
        entry = CStructGuided(FuseEntryParam)
        error = fcallback(F_LOOKUP, req, parent, name, entry)
        log("back from lookup entry=$(error == 0 ? entry : "")")
        error == 0 && fuse_reply_entry(req, entry)
        error == 0 && log("after fuse_reply_entry")
    finally
        error != 0 && fuse_reply_err(req, -error)
        error != 0 && log("fuse_reply_err(req, $(-error))")
    end
    nothing
end
F_FORGET = 4
function Cforget(req::FuseReq, ino::FuseIno, lookup::UInt64)
    try
        fcallback(F_FORGET, req, ino, lookup)
    finally
    end
end
F_GETATTR = 5
function Cgetattr(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    error = Base.UV_ENOTSUP
    try
        attr = CStructGuided(Cstat)
        attr_timeout = Ref(10.0)
        error = fcallback(F_GETATTR, req, ino, CStruct(fi), attr, attr_timeout)
        error == 0 && fuse_reply_attr(req, attr, attr_timeout[])
    catch ex
        log("getattr ex")
        rethrow()
    finally
        error != 0 && fuse_reply_err(req, -error)
    end
    nothing
end
F_SETATTR = 6
function Csetattr(req::FuseReq, ino::FuseIno, attr::Cstat, to_set::Cint, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_SETATTR, req, ino, attr, to_set, CStruct{FuseFileInfo}(fi))
        # fuse_reply_attr(req, attr, attr_timeout)
    finally
    end
end
F_READLINK = 7
function Creadlink(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_READLINK, req, ino)
    finally
    end
end
F_MKNOD = 8
function Cmknod(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, rdev::FuseDev)
    try
        fcallback(F_MKNOD, req, parent, name, mode, rdev)
    finally
    end
end
F_MKDIR = 9
function Cmkdir(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode) 
    try
        fcallback(F_MKDIR, req, parent, name, mode)
    finally
    end
end
F_UNLINK = 10
function Cunlink(req::FuseReq, parent::FuseIno, name::String)
    try
        fcallback(F_UNLINK, req, parent, name)
    finally
    end
end
F_RMDIR = 11
function Crmdir(req::FuseReq, parent::FuseIno, name::String)
    try
        fcallback(F_RMDIR, req, parent, name)
    finally
    end
end
F_SYMLINK = 12
function Csymlink(req::FuseReq, link::String, parent::FuseIno, name::String)
    try
        fcallback(F_SYMLINK, req, link, parent, name)
    finally
    end
end
F_RENAME = 13
function Crename(req::FuseReq, parent::FuseIno, name::String, newparent::FuseIno, newname::String, flags::Cuint)
    try
        fcallback(F_RENAME, req, parent, name, newparent, newname, flags)
    finally
    end
end
F_LINK = 14
function Clink(req::FuseReq, ino::FuseIno, newparent::FuseIno, newname::String)
    try
        fcallback(F_LINK, req, ino, newparent, newname)
    finally
    end
end
F_OPEN = 15
function Copen(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_OPEN, req, ino, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_READ = 16
function Cread(req::FuseReq, ino::FuseIno, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_READ, req, ino, size, off, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_WRITE = 17
function Cwrite(req::FuseReq, ino::FuseIno, buf::Vector{UInt8}, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_WRITE, req, ino, buf, size, off, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_FLUSH = 18
function Cflush(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_FLUSH, req, ino, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_RELEASE = 19
function Crelease(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_RELEASE, req, ino, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_FSYNC = 20
function Cfsync(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_FSYNC, req, ino, datasync, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_OPENDIR = 21
function Copendir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_OPENDIR, req, ino)
    finally
    end
end
F_READDIR = 22
function Creaddir(req::FuseReq, ino::FuseIno, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_READDIR, req, ino, size, off, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_RELEASEDIR = 23
function Creleasedir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_RELEASEDIR, req, ino, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_FSYNCDIR = 24
function Cfsyncdir(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_FSYNCDIR, req, ino, datasync, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_STATFS = 25
function Cstatfs(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_STATFS, req, ino)
    finally
    end
end
F_SETXATTR = 26
function Csetxattr(req::FuseReq, ino::FuseIno, name::String, value::String, size::Csize_t, flags::Cint)
    try
        fcallback(F_SETXATTR, req, ino, name, value, size, flags)
    finally
    end
end
F_GETXATTR = 27
function Cgetxattr(req::FuseReq, ino::FuseIno, name::String, size::Csize_t)
    try
        fcallback(F_GETXATTR, req, ino, name, size)
    finally
    end
end
F_LISTXATTR = 28
function Clistxattr(req::FuseReq, ino::FuseIno, size::Csize_t)
    try
        fcallback(F_LISTXATTR, req, ino, size)
    finally
    end
end
F_REMOVEXATTR = 29
function Cremovexattr(req::FuseReq, ino::FuseIno, name::String)
    try
        fcallback(F_REMOVEXATTR, req, ino, name)
    finally
    end
end
F_ACCESS = 30
function Caccess(req::FuseReq, ino::FuseIno, mask::Cint)
    try
        fcallback(F_ACCESS, req, ino, mask)
    finally
    end
end
F_CREATE = 31
function Ccreate(req::FuseReq, parent::FuseIno, name::String, mode::FuseMode, fi::Ptr{FuseFileInfo})
    try
        fcallback(F_CREATE, req, parent, name, mode, CStruct{FuseFileInfo}(fi))
    finally
    end
end
F_GETLK = 32
function Cgetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock})
    try
        fcallback(F_GETLK, req, ino, CStruct(fi), CStruct(lock))
    finally
    end
end
F_SETLK = 33
function Csetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock}, sleep::Cint)
    try
        fcallback(F_SETLK, req, ino, CStruct(fi), CStruct(lock), sleep)
    finally
    end
end
F_BMAP = 34
function Cbmap(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_BMAP, req, ino)
    finally
    end
end
F_IOCTL = 35
function Cioctl(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_IOCTL, req, ino)
    finally
    end
end
F_POLL = 36
function Cpoll(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_POLL, req, ino)
    finally
    end
end
F_WRITE_BUF = 37
function Cwrite_buf(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_WRITE_BUF, req, ino)
    finally
    end
end
F_RETRIEVE_REPLY = 38
function Cretrieve_reply(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_RETRIEVE_REPLY, req, ino)
    finally
    end
end
F_FORGET_MULTI = 39
function Cforget_multi(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_FORGET_MULTI, req, ino)
    finally
    end
end
F_FLOCK = 40
function Cflock(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_FLOCK, req, ino)
    finally
    end
end
F_FALLOCATE = 41
function Cfallocate(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_FALLOCATE, req, ino)
    finally
    end
end
F_READDIRPLUS = 42
function Creaddirplus(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_READDIRPLUS, req, ino)
    finally
    end
end
F_COPY_FILE_RANGE = 43
function Ccopy_file_range(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_COPY_FILE_RANGE, req, ino)
    finally
    end
end
F_LSEEK = 44
function Clseek(req::FuseReq, ino::FuseIno)
    try
        fcallback(F_LSEEK, req, ino)
    finally
    end
end


# to become const
ALL_FLO() = [
    (@cfunction Cinit Cvoid (Ptr{Nothing}, Ptr{Nothing})),
    (@cfunction Cdestroy Cvoid (Ptr{Nothing},)),
    (@cfunction Clookup  Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Cforget Cvoid (FuseReq, FuseIno, Culong)),
    (@cfunction Cgetattr Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Csetattr Cvoid (FuseReq, FuseIno, Ptr{Cstat}, Cint, Ptr{FuseFileInfo})),
    (@cfunction Creadlink Cvoid (FuseReq, FuseIno)),
    (@cfunction Cmknod Cvoid (FuseReq, FuseIno, Cstring, FuseMode, FuseDev)),
    (@cfunction Cmkdir Cvoid (FuseReq, FuseIno, Cstring, FuseMode)),
    (@cfunction Cunlink Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Crmdir Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Csymlink Cvoid (FuseReq, Cstring, FuseIno, Cstring)),
    (@cfunction Crename Cvoid (FuseReq, FuseIno, Cstring, FuseIno, Cstring)),
    (@cfunction Clink Cvoid (FuseReq, FuseIno, FuseIno, Cstring)),
    (@cfunction Copen Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cread Cvoid (FuseReq, FuseIno, Culong, Culong)),
    (@cfunction Cwrite Cvoid (FuseReq, FuseIno, Cstring, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cflush Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Crelease Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsync Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Copendir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Creaddir Cvoid (FuseReq, FuseIno, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creleasedir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsyncdir Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Cstatfs Cvoid (FuseReq, FuseIno)),
    (@cfunction Csetxattr Cvoid (FuseReq, FuseIno, Cstring, Cstring, Culong, Cint)),
    (@cfunction Cgetxattr Cvoid (FuseReq, FuseIno, Cstring, Culong)),
    (@cfunction Clistxattr Cvoid (FuseReq, FuseIno, Culong)),
    (@cfunction Cremovexattr Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Caccess Cvoid (FuseReq, FuseIno, Cint)),
    (@cfunction Ccreate Cvoid (FuseReq, FuseIno, Cstring, FuseMode, Ptr{FuseFileInfo})),
    (@cfunction Cgetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock})),
    (@cfunction Csetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}, Cint)),
    (@cfunction Cbmap Cvoid (FuseReq, FuseIno, Culong, Culong)),
    (@cfunction Cioctl Cvoid (FuseReq, FuseIno, Cuint, Ptr{Cvoid}, Ptr{FuseFileInfo}, Cuint, Ptr{Cvoid}, Culong, Culong)),
    (@cfunction Cpoll Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{FusePollHandle})),
    (@cfunction Cwrite_buf Cvoid (FuseReq, FuseIno, Ptr{FuseBufvec}, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cretrieve_reply Cvoid (FuseReq, Ptr{Cvoid}, FuseIno, Culong, Ptr{FuseBufvec})),
    (@cfunction Cforget_multi Cvoid (FuseReq, Culong, Ptr{FuseForgetData})),
    (@cfunction Cflock Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfallocate Cvoid (FuseReq, FuseIno, Cint, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creaddirplus Cvoid (FuseReq, FuseIno, Culong, Culong,Ptr{FuseFileInfo})),
    (@cfunction Ccopy_file_range Cvoid (FuseReq, FuseIno, Culong, Ptr{FuseFileInfo}, FuseIno, Culong, Ptr{FuseFileInfo}, Culong, Cint)),
    (@cfunction Clseek Cvoid (FuseReq, FuseIno, Culong, Cint, Ptr{FuseFileInfo}))
]


# reply functions to be called inside callback functions

function fuse_reply_attr(req::FuseReq, attr::CStructAccess{Cstat}, attr_timeout::Real)
    ccall((:fuse_reply_attr, :libfuse3), Cint, (FuseReq, Ptr{Cstat}, Cdouble), req, attr, attr_timeout)
end
function fuse_reply_bmap(req::FuseReq, idx::Integer)
    ccall((:fuse_reply_bmap, :libfuse3), Cint, (FuseReq, UInt64), req, idx)
end
function fuse_reply_buf(req::FuseReq, buf::Vector{UInt8}, size::Integer)
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Ptr{UInt8}, Csize_t), req, buf, size)
end
function fuse_reply_create(req::FuseReq, e::CStructAccess{FuseEntryParam}, fi::CStruct{FuseFileInfo})
    ccall((:fuse_reply_create, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}, Ptr{FuseFileInfo}), req, e, CStruct{FuseFileInfo}(fi))
end
function fuse_reply_data(req::FuseReq, bufv::CStructAccess{FuseBufvec}, flags::FuseBufCopyFlags)
    ccall((:fuse_reply_data, :libfuse3), Cint, (FuseReq, Ptr{FuseBufvec}, Cint), req, bufv, flags)
end
function fuse_reply_entry(req::FuseReq, entry::CStructAccess{FuseEntryParam})
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}), req, entry)
end
function fuse_reply_err(req::FuseReq, err::Integer)
    ccall((:fuse_reply_err, :libfuse3), Cint, (FuseReq, Cint), req, err)
end
function fuse_reply_ioctl(req::FuseReq, result::Integer, buf::CStruct, size::Integer)
    ccall((:fuse_reply_ioctl, :libfuse3), Cint, (FuseReq, Cint, Ptr{Nothing}, Csize_t), req, result, buf, size)
end
function fuse_reply_ioctl_iov(req::FuseReq, result::Integer, iov::CStructAccess{Ciovec}, count::Integer)
    ccall((:fuse_reply_ioctl_iov, :libfuse3), Cint, (FuseReq, Cint, Ptr{Ciovec}, Cint), req, result, iov, count)
end
function fuse_reply_ioctl_retry(req::FuseReq, in_iov::CStructAccess{Ciovec}, in_count::Integer, out_iov::CStruct{Ciovec}, out_count::Integer)
    ccall((:fuse_reply_ioctl_retry, :libfuse3), Cint, (FuseReq, Ptr{Ciovec}, Csize_t, Ptr{Ciovec}, Csize_t), req, in_iov, in_count, out_iov, out_count)
end
function fuse_reply_iov(req::FuseReq, iov::CStructAccess{Ciovec}, count::Integer)
    ccall((:fuse_reply_iov, :libfuse3), Cint, (FuseReq, Ptr{Ciovec}, Cint), req, iov, count)
end
function fuse_reply_lock(req::FuseReq, lock::CStructAccess{Cflock})
    ccall((:fuse_reply_lock, :libfuse3), Cint, (FuseReq, Ptr{Cflock}), req, lock)
end
function fuse_reply_lseek(req::FuseReq, off::Integer)
    ccall((:fuse_reply_lseek, :libfuse3), Cint, (FuseReq, Coff_t), req, off)
end
function fuse_reply_none(req::FuseReq)
    ccall((:fuse_reply_none, :libfuse3), Cint, (FuseReq, ), req)
end
function fuse_reply_open(req::FuseReq, fi::CStructAccess{FuseFileInfo})
    ccall((:fuse_reply_open, :libfuse3), Cint, (FuseReq, Ptr{FuseFileInfo}), req, CStruct{FuseFileInfo}(fi))
end
function fuse_reply_poll(req::FuseReq, revents::Integer )
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Cuint), req, revents)
end
function fuse_reply_readlink(req::FuseReq, link::String)
    ccall((:fuse_reply_readlink, :libfuse3), Cint, (FuseReq, Cstring), req, link)
end
function fuse_reply_statfs(req::FuseReq, stbuf::CStructAccess{Cstatvfs})
    ccall((:fuse_reply_statfs, :libfuse3), Cint, (FuseReq, Ptr{Cstatvfs}), req, stbuf)
end
function fuse_reply_write(req::FuseReq, count::Integer)
    ccall((:fuse_reply_write, :libfuse3), Cint, (FuseReq, Csize_t), req, count)
end
function fuse_reply_xattr(req::FuseReq, count::Integer)
    ccall((:fuse_reply_xattr, :libfuse3), Cint, (FuseReq, Csize_t), req, count)
end

# accessors for req
function fuse_req_ctx(req::FuseReq)
    CStruct{FuseCtx}(ccall((:fuse_req_ctx, :libfuse3), Ptr{FuseCtx}, (FuseReq,), req))
end
function fuse_req_getgroups(req::FuseReq, list::Vector{Cgid_t})
    ccall((:fuse_req_getgroups, :libfuse3), Cint, (FuseReq, Cint, Ptr{Cgid_t}), req, length(list), pointer_from_vector(list))
end
function fuse_req_interrupt_func(req::FuseReq, func::Ptr{Nothing}, data::Any)
    ccall((:fuse_req_ctx, :libfuse3), Cvoid, (FuseReq, Ptr{Nothing}, Ptr{Nothing}), req, func, data)
end
function fuse_req_interrupted(req::FuseReq)
    ccall((:fuse_req_interrupted, :libfuse3), Cint, (FuseReq,), req)
end
function fuse_req_userdata(req::FuseReq)
    ccall((:fuse_req_userdata, :libfuse3), Ptr{Nothing}, (FuseReq,), req)
end
function fuse_req_userdata(req::FuseReq, ::Type{T}) where T
    unsafe_pointer_to_objref(ccall((:fuse_req_userdata, :libfuse3), Ptr{T}, (FuseReq,), req))
end
