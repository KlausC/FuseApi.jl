# C- entrypoints for all lowlevel callback functions

export fuse_session_new, fuse_session_destroy, fuse_session_mount, fuse_session_unmount, fuse_session_loop
export fuse_reply_attr, fuse_reply_bmap, fuse_reply_buf, fuse_reply_create, fuse_reply_data, fuse_reply_entry, fuse_reply_err
export fuse_reply_ioctl, fuse_reply_ioctl_iov, fuse_reply_ioctl_retry, fuse_reply_iov, fuse_reply_lock, fuse_reply_lseek, fuse_reply_none
export fuse_reply_attrfuse_reply_none, fuse_reply_open, fuse_reply_poll, fuse_reply_readlink, fuse_reply_statfs, fuse_reply_write, fuse_reply_xattr
export fuse_add_direntry, fuse_add_direntry_plus, fuse_req_ctx

export fuse_req_ctx, fuse_req_getgroups, fuse_req_interrupt_func, fuse_req_interrupted, fuse_req_userdata

# F_INIT = 1
function Ginit(init::Function, fs::Any)
    Cinit = let init = init, fs = fs
        function (::Ptr{Nothing}, conn::Ptr{FuseConnInfo})
            docall() do
                init(fs, CStruct{FuseConnInfo}(conn))
            end
        end
    end
    @cfunction $Cinit Cvoid (Ptr{Nothing}, Ptr{FuseConnInfo})
end
# F_DESTROY = 2
function Gdestroy(destroy::Function, fs::Any)
    function Cdestroy(::Ptr{Nothing})
        docall() do
            destroy(fs)
        end
    end
    (@cfunction $Cdestroy Cvoid (Ptr{Nothing},))
end
# F_LOOKUP = 3
function Glookup(lookup::Function, fs::Any)
    function Clookup(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            error = lookup(fs, req, parent, name)
            error
        end
        nothing
    end
    (@cfunction $Clookup  Cvoid (FuseReq, FuseIno, Cstring))
end
# F_FORGET = 4
function Gforget(forget::Function, fs::Any)
    function Cforget(req::FuseReq, ino::FuseIno, lookup::Cuint64_t)
        docall(req) do
            forget(fs, req, ino, lookup)
        end
    end
    (@cfunction $Cforget Cvoid (FuseReq, FuseIno, Cuint64_t))
end
# F_GETATTR = 5
function Ggetattr(getattr::Function, fs::Any)
    function Cgetattr(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            getattr(fs, req, ino, CStruct(fi))
        end
        nothing
    end
    (@cfunction $Cgetattr Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_SETATTR = 6
function Gsetattr(setattr::Function, fs::Any)
    function Csetattr(req::FuseReq, ino::FuseIno, attr::Ptr{Cstat}, to_set::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
             setattr(fs, req, ino, CStruct(attr), to_set, CStruct(fi))
        end
    end
    (@cfunction $Csetattr Cvoid (FuseReq, FuseIno, Ptr{Cstat}, Cint, Ptr{FuseFileInfo}))
end
# F_READLINK = 7
function Greadlink(readlink::Function, fs::Any)
    function Creadlink(req::FuseReq, ino::FuseIno)
        docall(req) do
            readlink(fs, req, ino)
        end
    end
    (@cfunction $Creadlink Cvoid (FuseReq, FuseIno))
end
# F_MKNOD = 8
function Gmknod(mknod::Function, fs::Any)
    function Cmknod(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode, rdev::FuseDev)
        docall(req) do
            name = unsafe_string(name)
            mknod(fs, req, parent, name, mode, rdev)
        end
    end
    (@cfunction $Cmknod Cvoid (FuseReq, FuseIno, Cstring, FuseMode, FuseDev))
end
# F_MKDIR = 9
function Gmkdir(mkdir::Function, fs::Any)
    function Cmkdir(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode)
        docall(req) do
            name = unsafe_string(name)
            mkdir(fs, req, parent, name, mode)
        end
    end
    (@cfunction $Cmkdir Cvoid (FuseReq, FuseIno, Cstring, FuseMode))
end
# F_UNLINK = 10
function Gunlink(unlink::Function, fs::Any)
    function Cunlink(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            unlink(fs, req, parent, name)
        end
    end
    (@cfunction $Cunlink Cvoid (FuseReq, FuseIno, Cstring))
end
# F_RMDIR = 11
function Grmdir(rmdir::Function, fs::Any)
    function Crmdir(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            rmdir(fs, req, parent, name)
        end
    end
    (@cfunction $Crmdir Cvoid (FuseReq, FuseIno, Cstring))
end
# F_SYMLINK = 12
function Gsymlink(symlink::Function, fs::Any)
    function Csymlink(req::FuseReq, link::Cstring, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            link = unsafe_string(link)
            symlink(fs, req, link, parent, name)
        end
    end
    (@cfunction $Csymlink Cvoid (FuseReq, Cstring, FuseIno, Cstring))
end
# F_RENAME = 13
function Grename(rename::Function, fs::Any)
    function Crename(req::FuseReq, parent::FuseIno, name::Cstring, newparent::FuseIno, newname::Cstring, flags::Cuint)
        docall(req) do
            name = unsafe_string(name)
            newname = unsafe_string(newname)
            rename(fs, req, parent, name, newparent, newname, flags)
        end
    end
    (@cfunction $Crename Cvoid (FuseReq, FuseIno, Cstring, FuseIno, Cstring, Cuint))
end
# F_LINK = 14
function Glink(link::Function, fs::Any)
    function Clink(req::FuseReq, ino::FuseIno, newparent::FuseIno, newname::Cstring)
        docall(req) do
            println("link($ino, $newparent, $newname)")
            newname = unsafe_string(newname)
            link(fs, req, ino, newparent, newname)
        end
    end
    (@cfunction $Clink Cvoid (FuseReq, FuseIno, FuseIno, Cstring))
end
# F_OPEN = 15
function Gopen(open::Function, fs::Any)
    function Copen(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            open(fs, req, ino, CStruct(fi))
        end
    end
    (@cfunction $Copen Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_READ = 16
function Gread(read::Function, fs::Any)
    function Cread(req::FuseReq, ino::FuseIno, size::Csize_t, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            read(fs, req, ino, size, off, CStruct(fi))
        end
    end
    (@cfunction $Cread Cvoid (FuseReq, FuseIno, Csize_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_WRITE = 17
function Gwrite(write::Function, fs::Any)
    function Cwrite(req::FuseReq, ino::FuseIno, cbuf::Ptr{UInt8}, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            write(fs, req, ino, CVector{UInt8}(cbuf), size, off, CStruct(fi))
        end
    end
    (@cfunction $Cwrite Cvoid (FuseReq, FuseIno, Ptr{UInt8}, Csize_t, Csize_t, Ptr{FuseFileInfo}))
end
# F_FLUSH = 18
function Gflush(flush::Function, fs::Any)
    function Cflush(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            flush(fs, req, ino, CStruct(fi))
        end
    end
    (@cfunction $Cflush Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_RELEASE = 19
function Grelease(release::Function, fs::Any)
    function Crelease(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            release(fs, req, ino, CStruct(fi))
        end
    end
    (@cfunction $Crelease Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_FSYNC = 20
function Gfsync(fsync::Function, fs::Any)
    function Cfsync(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            fsync(fs, req, ino, datasync, CStruct(fi))
        end
    end
    (@cfunction $Cfsync Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo}))
end
# F_OPENDIR = 21
function Gopendir(opendir::Function, fs::Any)
    function Copendir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            opendir(fs, req, ino, CStruct(fi))
        end
    end
    (@cfunction $Copendir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_READDIR = 22
function Greaddir(readdir::Function, fs::Any)
    function Creaddir(req::FuseReq, ino::FuseIno, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            readdir(fs, req, ino, size, off, CStruct(fi))
        end
    end
    (@cfunction $Creaddir Cvoid (FuseReq, FuseIno, Csize_t, Csize_t, Ptr{FuseFileInfo}))
end
# F_RELEASEDIR = 23
function Greleasedir(releasedir::Function, fs::Any)
    function Creleasedir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            releasedir(fs, req, ino, CStruct(fi))
        end
    end
    (@cfunction $Creleasedir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_FSYNCDIR = 24
function Gfsyncdir(fsyncdir::Function, fs::Any)
    function Cfsyncdir(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            fsyncdir(fs, req, ino, datasync, CStruct(fi))
        end
    end
    (@cfunction $Cfsyncdir Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo}))
end
# F_STATFS = 25
function Gstatfs(statfs::Function, fs::Any)
    function Cstatfs(req::FuseReq, ino::FuseIno)
        docall(req) do
            statfs(fs, req, ino)
        end
    end
    (@cfunction $Cstatfs Cvoid (FuseReq, FuseIno))
end
# F_SETXATTR = 26
function Gsetxattr(setxattr::Function, fs::Any)
    function Csetxattr(req::FuseReq, ino::FuseIno, name::Cstring, value::Ptr{UInt8}, size::Csize_t, flags::Cint)
        docall(req) do
            name = unsafe_string(name)
            value = copy(unsafe_wrap(Array, value, size))
            setxattr(fs, req, ino, name, value, flags)
        end
    end
    (@cfunction $Csetxattr Cvoid (FuseReq, FuseIno, Cstring, Ptr{UInt8}, Csize_t, Cint))
end
# F_GETXATTR = 27
function Ggetxattr(getxattr::Function, fs::Any)
    function Cgetxattr(req::FuseReq, ino::FuseIno, name::Cstring, size::Csize_t)
        docall(req) do
            println("getxattr($ino, $name)")
            name = unsafe_string(name)
            getxattr(fs, req, ino, name, size)
        end
    end
    (@cfunction $Cgetxattr Cvoid (FuseReq, FuseIno, Cstring, Csize_t))
end
# F_LISTXATTR = 28
function Glistxattr(listxattr::Function, fs::Any)
    function Clistxattr(req::FuseReq, ino::FuseIno, size::Csize_t)
        docall(req) do
            listxattr(fs, req, ino, size)
        end
    end
    (@cfunction $Clistxattr Cvoid (FuseReq, FuseIno, Csize_t))
end
# F_REMOVEXATTR = 29
function Gremovexattr(removexattr::Function, fs::Any)
    function Cremovexattr(req::FuseReq, ino::FuseIno, name::Cstring)
        docall(req) do
            println("removexattr($ino, $name)")
            name = unsafe_string(name)
            removexattr(fs, req, ino, name)
        end
    end
    (@cfunction $Cremovexattr Cvoid (FuseReq, FuseIno, Cstring))
end
# F_ACCESS = 30
function Gaccess(access::Function, fs::Any)
    function Caccess(req::FuseReq, ino::FuseIno, mask::Cint)
        docall(req) do
            access(fs, req, ino, mask)
        end
    end
    (@cfunction $Caccess Cvoid (FuseReq, FuseIno, Cint))
end
# F_CREATE = 31
function Gcreate(create::Function, fs::Any)
    function Ccreate(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode, fi::Ptr{FuseFileInfo})
        docall(req) do
            name = unsafe_string(name)
            create(fs, req, parent, name, mode, CStruct(fi))
        end
    end
    (@cfunction $Ccreate Cvoid (FuseReq, FuseIno, Cstring, FuseMode, Ptr{FuseFileInfo}))
end
# F_GETLK = 32
function Ggetlk(getlk::Function, fs::Any)
    function Cgetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock})
        docall(req) do
            getlk(fs, req, ino, CStruct(fi), CStruct(lock))
        end
    end
    (@cfunction $Cgetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}))
end
# F_SETLK = 33
function Gsetlk(setlk::Function, fs::Any)
    function Csetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock}, sleep::Cint)
        docall(req) do
            setlk(fs, req, ino, CStruct(fi), CStruct(lock), sleep)
        end
    end
    (@cfunction $Csetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}, Cint))
# F_BMAP = 34
function Gbmap(bmap::Function, fs::Any)
    function Cbmap(req::FuseReq, ino::FuseIno, blocksize::Csize_t, idx::Cuint64_t)
        docall(req) do
            bmap(fs, req, ino, blocksize, idx)
        end
    end
    (@cfunction $Cbmap Cvoid (FuseReq, FuseIno, Csize_t, Cuint64_t))
end
end
# F_IOCTL = 35
function Gioctl(ioctl::Function, fs::Any)
    function Cioctl(req::FuseReq, ino::FuseIno, cmd::Cuint, arg::Ptr{Nothing}, fi::Ptr{FuseFileInfo}, flags::Cuint, in_buf::Ptr{Ptr{Cvoid}}, in_bufsz::Csize_t, out_bufsz::Csize_t)
        docall(req) do
            ioctl(fs, req, ino, cmd, arg, CStruct(fi), flags, in_buf, in_bufsz, out_bufsz)
        end
    end
    (@cfunction $Cioctl Cvoid (FuseReq, FuseIno, Cuint, Ptr{Cvoid}, Ptr{FuseFileInfo}, Cuint, Ptr{Ptr{Cvoid}}, Csize_t, Csize_t))
end
# F_POLL = 36
function Gpoll(poll::Function, fs::Any)
    function Cpoll(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, ph::Ptr{FusePollHandle})
        docall(req) do
            poll(fs, req, ino, CStruct(fi), CStruct(ph))
        end
    end
    (@cfunction $Cpoll Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{FusePollHandle}))
end
# F_WRITE_BUF = 37
function Gwrite_buf(write_buf::Function, fs::Any)
    function Cwrite_buf(req::FuseReq, ino::FuseIno, bufv::Ptr{FuseBufvec}, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            write_buf(fs, req, ino, CStruct(bufv), off, CStruct(fi))
        end
    end
    (@cfunction $Cwrite_buf Cvoid (FuseReq, FuseIno, Ptr{FuseBufvec}, Coff_t, Ptr{FuseFileInfo}))
end
# F_RETRIEVE_REPLY = 38
function Gretrieve_reply(retrieve_reply::Function, fs::Any)
    function Cretrieve_reply(req::FuseReq, cookie::Ptr{Cvoid}, ino::FuseIno, off::Coff_t, bufv::Ptr{FuseBufvec})
        docall(req) do
            retrieve_reply(fs, req, cookie, ino, off, CStruct(bufv))
        end
    end
    (@cfunction $Cretrieve_reply Cvoid (FuseReq, Ptr{Cvoid}, FuseIno, Coff_t, Ptr{FuseBufvec}))
end
# F_FORGET_MULTI = 39
function Gforget_multi(forget_multi::Function, fs::Any)
    function Cforget_multi(req::FuseReq, count::Csize_t, forgets::Ptr{FuseForgetData})
        docall(req) do
            forget_multi(fs, req, count, CStruct{forgets})
        end
    end
    (@cfunction $Cforget_multi Cvoid (FuseReq, Csize_t, Ptr{FuseForgetData}))
end
# F_FLOCK = 40
function Gflock(flock::Function, fs::Any)
    function Cflock(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, op::Cint)
        docall(req) do
            flock(fs, req, ino, CStruct(fi), op)
        end
    end
    (@cfunction $Cflock Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Cint))
end
# F_FALLOCATE = 41
function Gfallocate(fallocate::Function, fs::Any)
    function Cfallocate(req::FuseReq, ino::FuseIno, mode::Cint, off::Coff_t, length::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            fallocate(fs, req, ino, mode, off, length, CStruct(fi))
        end
    end
    (@cfunction $Cfallocate Cvoid (FuseReq, FuseIno, Cint, Coff_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_READDIRPLUS = 42
function Greaddirplus(readdirplus::Function, fs::Any)
    #, size_t size, off_t off, struct fuse_file_info *fi)
    function Creaddirplus(req::FuseReq, ino::FuseIno, size::Csize_t, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            readdirplus(fs, req, ino, size, off, CStruct(fi))
        end
    end
    (@cfunction $Creaddirplus Cvoid (FuseReq, FuseIno, Csize_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_COPY_FILE_RANGE = 43
function Gcopy_file_range(copy_file_range::Function, fs::Any)
    function Ccopy_file_range(req::FuseReq, ino_in::FuseIno, off_in::Coff_t, fi_in::Ptr{FuseFileInfo}, ino_out::FuseIno, off_out::Coff_t, fi_out::Ptr{FuseFileInfo}, len::Csize_t, flags::Cint)
        docall(req) do
            copy_file_range(fs, req, ino_in, off_in, CStruct(fi_in), ino_out, off_out, CStruct(fi_out), len, flags)
        end
    end
    (@cfunction $Ccopy_file_range Cvoid (FuseReq, FuseIno, Coff_t, Ptr{FuseFileInfo}, FuseIno, Coff_t, Ptr{FuseFileInfo}, Csize_t, Cint))
end
# F_LSEEK = 44
function Glseek(lseek::Function, fs::Any)
    function Clseek(req::FuseReq, ino::FuseIno, off::Coff_t, whence::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            lseek(fs, req, ino, off, whence, CStruct(fi))
        end
    end
    (@cfunction $Clseek Cvoid (FuseReq, FuseIno, Coff_t, Cint, Ptr{FuseFileInfo}))
end

# reply functions to be called inside callback functions

function fuse_reply_attr(req::FuseReq, attr::CStructAccess{Cstat}, attr_timeout::Real)
    ccall((:fuse_reply_attr, :libfuse3), Cint, (FuseReq, Ptr{Cstat}, Cdouble), req, attr, attr_timeout)
end
function fuse_reply_bmap(req::FuseReq, idx::Integer)
    ccall((:fuse_reply_bmap, :libfuse3), Cint, (FuseReq, UInt64), req, idx)
end
function fuse_reply_buf(req::FuseReq, buf::Vector{UInt8}, size::Integer)
    ccall((:fuse_reply_buf, :libfuse3), Cint, (FuseReq, Ptr{UInt8}, Csize_t), req, pointer(buf), size)
end
function fuse_reply_create(req::FuseReq, e::CStructAccess{FuseEntryParam}, fi::CStruct{FuseFileInfo})
    ccall((:fuse_reply_create, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}, Ptr{FuseFileInfo}), req, e, fi)
end
function fuse_reply_data(req::FuseReq, bufv::CStructAccess{FuseBufvec}, flags::FuseBufCopyFlags)
    ccall((:fuse_reply_data, :libfuse3), Cint, (FuseReq, Ptr{FuseBufvec}, Cint), req, bufv, flags.flag)
end
function fuse_reply_entry(req::FuseReq, entry::CStructAccess{FuseEntryParam})
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}), req, entry)
end
function fuse_reply_none(req::FuseReq)
    ccall((:fuse_reply_none, :libfuse3), Cint, (FuseReq,), req)
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
function fuse_reply_open(req::FuseReq, fi::CStructAccess{FuseFileInfo})
    ccall((:fuse_reply_open, :libfuse3), Cint, (FuseReq, Ptr{FuseFileInfo}), req, fi)
end
function fuse_reply_poll(req::FuseReq, revents::Integer )
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Cuint), req, revents)
end
function fuse_reply_readlink(req::FuseReq, link::Vector{UInt8})
    ccall((:fuse_reply_readlink, :libfuse3), Cint, (FuseReq, Ptr{UInt8}), req, link)
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
    ptr_to_userdata(ccall((:fuse_req_userdata, :libfuse3), Ptr{Any}, (FuseReq,), req))
end

# helper function to support readdir
function fuse_add_direntry(req::FuseReq, buf::AbstractVector{UInt8}, name::String, st::CStructAccess{Cstat}, off::Integer)
    bufsz = length(buf)
    ccall((:fuse_add_direntry, :libfuse3), Csize_t, (FuseReq, Ptr{UInt8}, Csize_t, Cstring, Ptr{Cstat}, Coff_t), req, buf, bufsz, name, st, off)
end

function fuse_add_direntry_plus(req::FuseReq, buf::AbstractVector{UInt8}, name::String, e::CStructAccess{FuseEntryParam}, off::Integer)
    bufsz = length(buf)
    ccall((:fuse_add_direntry_plus, :libfuse3), Csize_t, (FuseReq, Ptr{UInt8}, Csize_t, Cstring, Ptr{FuseEntryParam}, Coff_t), req, buf, bufsz, name, e, off)
end

function fuse_req_ctx(req::FuseReq)
    cdata = ccall((:fuse_req_ctx, :libfuse3), Ptr{FuseCtx}, (FuseReq,), req)
    CStruct(cdata)
end

# session functions

function fuse_session_new(fargs::CStructAccess{FuseCmdlineArgs}, callbacks::Vector{CFu})
    ccall((:fuse_session_new, :libfuse3), Ptr{Nothing},
        (Ptr{FuseCmdlineArgs}, Ptr{CFu}, Cint, Ptr{Nothing}),
        fargs, callbacks, sizeof(callbacks), C_NULL)
end

function fuse_session_mount(se, mountpoint)
    ccall((:fuse_session_mount, :libfuse3), Cint, (Ptr{Nothing}, Cstring), se, mountpoint)
end

function fuse_session_loop(se)
    ccall((:fuse_session_loop, :libfuse3), Cint, (Ptr{Nothing},), se)
end

function fuse_session_loop_mt(se, cfg::FuseLoopConfig)
    ccall((:fuse_session_loop_mt, :libfuse3), Cint, (Ptr{Nothing}, Ref{FuseLoopConfig}), se, cfg)
end

function fuse_session_unmount(se)
    ccall((:fuse_session_unmount, :libfuse3), Cvoid, (Ptr{Nothing},), se)
end

function fuse_session_destroy(se)
    ccall((:fuse_session_destroy, :libfuse3), Cvoid, (Ptr{Nothing},), se)
end

function ptr_to_userdata(u::Ptr)
    println("ptr_to_userdata($u)")
    ud = Base.unsafe_pointer_to_objref(u)
    ud isa Ref ? getindex(ud) : ud
end