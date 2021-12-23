# C- entrypoints for all lowlevel callback functions

export fuse_reply_attr, fuse_reply_bmap, fuse_reply_buf, fuse_reply_create, fuse_reply_data, fuse_reply_entry, fuse_reply_err
export fuse_reply_ioctl, fuse_reply_ioctl_iov, fuse_reply_ioctl_retry, fuse_reply_iov, fuse_reply_lock, fuse_reply_lseek
export fuse_reply_attrfuse_reply_none, fuse_reply_open, fuse_reply_poll, fuse_reply_readlink, fuse_reply_statfs, fuse_reply_write, fuse_reply_xattr
export fuse_add_direntry, fuse_add_direntry_plus

export fuse_req_ctx, fuse_req_getgroups, fuse_req_interrupt_func, fuse_req_interrupted, fuse_req_userdata

# F_INIT = 1
function Ginit(init)
    function Cinit(userdata::Ptr{Nothing}, conn::Ptr{FuseConnInfo})
        docall() do
            init(userdata, CStruct{FuseConnInfo}(conn))
        end
    end
    @cfunction $Cinit Cvoid (Ptr{Nothing}, Ptr{FuseConnInfo})
end
# F_DESTROY = 2
function Gdestroy(destroy)
    function Cdestroy(userdata::Ptr{Nothing})
        docall() do
            destroy(userdata)       
        end
    end
    (@cfunction $Cdestroy Cvoid (Ptr{Nothing},))
end
# F_LOOKUP = 3
function Glookup(lookup)
    function Clookup(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            error = lookup(req, parent, name)
            error
        end
        nothing
    end
    (@cfunction $Clookup  Cvoid (FuseReq, FuseIno, Cstring))
end
# F_FORGET = 4
function Gforget(forget)
    function Cforget(req::FuseReq, ino::FuseIno, lookup::Cuint64_t)
        docall(req) do
            forget(req, ino, lookup)
        end
    end
    (@cfunction $Cforget Cvoid (FuseReq, FuseIno, Cuint64_t))
end
# F_GETATTR = 5
function Ggetattr(getattr)
    function Cgetattr(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            getattr(req, ino, CStruct(fi))
        end
        nothing
    end
    (@cfunction $Cgetattr Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_SETATTR = 6
function Gsetattr(setattr)
    function Csetattr(req::FuseReq, ino::FuseIno, attr::Ptr{Cstat}, to_set::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
             setattr(req, ino, CStruct(attr), to_set, CStruct(fi))
        end
    end
    (@cfunction $Csetattr Cvoid (FuseReq, FuseIno, Ptr{Cstat}, Cint, Ptr{FuseFileInfo}))
end
# F_READLINK = 7
function Greadlink(readlink)
    function Creadlink(req::FuseReq, ino::FuseIno)
        docall(req) do
            readlink(req, ino)      
        end
    end
    (@cfunction $Creadlink Cvoid (FuseReq, FuseIno))
end
# F_MKNOD = 8
function Gmknod(mknod)
    function Cmknod(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode, rdev::FuseDev)
        docall(req) do
            name = unsafe_string(name)
            mknod(req, parent, name, mode, rdev)       
        end
    end
    (@cfunction $Cmknod Cvoid (FuseReq, FuseIno, Cstring, FuseMode, FuseDev))
end
# F_MKDIR = 9
function Gmkdir(mkdir)
    function Cmkdir(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode)
        docall(req) do
            name = unsafe_string(name)
            mkdir(req, parent, name, mode)     
        end
    end
    (@cfunction $Cmkdir Cvoid (FuseReq, FuseIno, Cstring, FuseMode))
end
# F_UNLINK = 10
function Gunlink(unlink)
    function Cunlink(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            unlink(req, parent, name)     
        end
    end
    (@cfunction $Cunlink Cvoid (FuseReq, FuseIno, Cstring))
end
# F_RMDIR = 11
function Grmdir(rmdir)
    function Crmdir(req::FuseReq, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            rmdir(req, parent, name)       
        end
    end
    (@cfunction $Crmdir Cvoid (FuseReq, FuseIno, Cstring))
end
# F_SYMLINK = 12
function Gsymlink(symlink)
    function Csymlink(req::FuseReq, link::String, parent::FuseIno, name::Cstring)
        docall(req) do
            name = unsafe_string(name)
            symlink(req, link, parent, name)      
        end
    end
    (@cfunction $Csymlink Cvoid (FuseReq, Cstring, FuseIno, Cstring))
end
# F_RENAME = 13
function Grename(rename)
    function Crename(req::FuseReq, parent::FuseIno, name::Cstring, newparent::FuseIno, newname::Cstring, flags::Cuint)
        docall(req) do
            name = unsafe_string(name)
            newname = unsafe_string(newname)
            rename(req, parent, name, newparent, newname, flags)       
        end
    end
    (@cfunction $Crename Cvoid (FuseReq, FuseIno, Cstring, FuseIno, Cstring, Cuint))
end
# F_LINK = 14
function Glink(link)
    function Clink(req::FuseReq, ino::FuseIno, newparent::FuseIno, newname::Cstring)
        docall(req) do          
            newname = unsafe_string(newname)
            link(req, ino, newparent, newname)     
        end
    end
    (@cfunction $Clink Cvoid (FuseReq, FuseIno, FuseIno, Cstring))
end
# F_OPEN = 15
function Gopen(open)
    function Copen(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            open(req, ino, CStruct(fi))       
        end
    end
    (@cfunction $Copen Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_READ = 16
function Gread(read)
    function Cread(req::FuseReq, ino::FuseIno, size::Csize_t, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            read(req, ino, size, off, CStruct(fi))           
        end
    end
    (@cfunction $Cread Cvoid (FuseReq, FuseIno, Csize_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_WRITE = 17
function Gwrite(write)
    function Cwrite(req::FuseReq, ino::FuseIno, cbuf::Ptr{UInt8}, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            write(req, ino, CVector{UInt8}(cbuf), size, off, CStruct(fi))   
        end
    end
    (@cfunction $Cwrite Cvoid (FuseReq, FuseIno, Ptr{UInt8}, Csize_t, Csize_t, Ptr{FuseFileInfo}))
end
# F_FLUSH = 18
function Gflush(flush)
    function Cflush(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            flush(req, ino, CStruct(fi))     
        end
    end
    (@cfunction $Cflush Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_RELEASE = 19
function Grelease(release)
    function Crelease(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            release(req, ino, CStruct(fi))     
        end
    end
    (@cfunction $Crelease Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_FSYNC = 20
function Gfsync(fsync)
    function Cfsync(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            fsync(req, ino, datasync, CStruct(fi))       
        end
    end
    (@cfunction $Cfsync Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo}))
end
# F_OPENDIR = 21
function Gopendir(opendir)
    function Copendir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            opendir(req, ino, CStruct(fi))       
        end
    end
    (@cfunction $Copendir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_READDIR = 22
function Greaddir(readdir)
    function Creaddir(req::FuseReq, ino::FuseIno, size::Csize_t, off::Csize_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            readdir(req, ino, size, off, CStruct(fi))    
        end
    end
    (@cfunction $Creaddir Cvoid (FuseReq, FuseIno, Csize_t, Csize_t, Ptr{FuseFileInfo}))
end
# F_RELEASEDIR = 23
function Greleasedir(releasedir)
    function Creleasedir(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo})
        docall(req) do
            releasedir(req, ino, CStruct(fi))       
        end
    end
    (@cfunction $Creleasedir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}))
end
# F_FSYNCDIR = 24
function Gfsyncdir(fsyncdir)
    function Cfsyncdir(req::FuseReq, ino::FuseIno, datasync::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            fsyncdir(req, ino, datasync, CStruct(fi))    
        end
    end
    (@cfunction $Cfsyncdir Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo}))
end
# F_STATFS = 25
function Gstatfs(statfs)
    function Cstatfs(req::FuseReq, ino::FuseIno)
        docall(req) do
            statfs(req, ino)      
        end
    end
    (@cfunction $Cstatfs Cvoid (FuseReq, FuseIno))
end
# F_SETXATTR = 26
function Gsetxattr(setxattr)
    function Csetxattr(req::FuseReq, ino::FuseIno, name::Cstring, value::Cstring, size::Csize_t, flags::Cint)
        docall(req) do          
            name = unsafe_string(name)
            value = unsafe_string(value)
            setxattr(req, ino, name, value, size, flags)     
        end
    end
    (@cfunction $Csetxattr Cvoid (FuseReq, FuseIno, Cstring, Cstring, Csize_t, Cint))
end
# F_GETXATTR = 27
function Ggetxattr(getxattr)
    function Cgetxattr(req::FuseReq, ino::FuseIno, name::Cstring, size::Csize_t)
        docall(req) do          
            name = unsafe_string(name)
            getxattr(req, ino, name, size)     
        end
    end
    (@cfunction $Cgetxattr Cvoid (FuseReq, FuseIno, Cstring, Csize_t))
end
# F_LISTXATTR = 28
function Glistxattr(listxattr)
    function Clistxattr(req::FuseReq, ino::FuseIno, size::Csize_t)
        docall(req) do
            listxattr(req, ino, size)      
        end
    end
    (@cfunction $Clistxattr Cvoid (FuseReq, FuseIno, Csize_t))
end
# F_REMOVEXATTR = 29
function Gremovexattr(removexattr)
    function Cremovexattr(req::FuseReq, ino::FuseIno, name::Cstring)
        docall(req) do          
            name = unsafe_string(name)
            removexattr(req, ino, name)      
        end
    end
    (@cfunction $Cremovexattr Cvoid (FuseReq, FuseIno, Cstring))
# F_ACCESS = 30
function Gaccess(access)
    function Caccess(req::FuseReq, ino::FuseIno, mask::Cint)
        docall(req) do
            access(req, ino, mask)       
        end
    end
    (@cfunction $Caccess Cvoid (FuseReq, FuseIno, Cint))
end
end
# F_CREATE = 31
function Gcreate(create)
    function Ccreate(req::FuseReq, parent::FuseIno, name::Cstring, mode::FuseMode, fi::Ptr{FuseFileInfo})
        docall(req) do          
            name = unsafe_string(name)
            create(req, parent, name, mode, CStruct(fi))       
        end
    end
    (@cfunction $Ccreate Cvoid (FuseReq, FuseIno, Cstring, FuseMode, Ptr{FuseFileInfo}))
end
# F_GETLK = 32
function Ggetlk(getlk)
    function Cgetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock})
        docall(req) do
            getlk(req, ino, CStruct(fi), CStruct(lock))          
        end
    end
    (@cfunction $Cgetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}))
end
# F_SETLK = 33
function Gsetlk(setlk)
    function Csetlk(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, lock::Ptr{Cflock}, sleep::Cint)
        docall(req) do
            setlk(req, ino, CStruct(fi), CStruct(lock), sleep)        
        end
    end
    (@cfunction $Csetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}, Cint))
# F_BMAP = 34
function Gbmap(bmap)
    function Cbmap(req::FuseReq, ino::FuseIno, blocksize::Csize_t, idx::Cuint64_t)
        docall(req) do
            bmap(req, ino, blocksize, idx)           
        end
    end
    (@cfunction $Cbmap Cvoid (FuseReq, FuseIno, Csize_t, Cuint64_t))
end
end
# F_IOCTL = 35
function Gioctl(ioctl)
    function Cioctl(req::FuseReq, ino::FuseIno, cmd::Cuint, arg::Ptr{Nothing}, fi::Ptr{FuseFileInfo}, flags::Cuint, in_buf::Ptr{Ptr{Cvoid}}, in_bufsz::Csize_t, out_bufsz::Csize_t)
        docall(req) do
            ioctl(req, ino, cmd, arg, CStruct(fi), flags, in_buf, in_bufsz, out_bufsz)         
        end
    end
    (@cfunction $Cioctl Cvoid (FuseReq, FuseIno, Cuint, Ptr{Cvoid}, Ptr{FuseFileInfo}, Cuint, Ptr{Ptr{Cvoid}}, Csize_t, Csize_t))
end
# F_POLL = 36
function Gpoll(poll)
    function Cpoll(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, ph::Ptr{FusePollHandle})
        docall(req) do
            poll(req, ino, CStruct(fi), CStruct(ph))          
        end
    end
    (@cfunction $Cpoll Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{FusePollHandle}))
end
# F_WRITE_BUF = 37
function Gwrite_buf(write_buf)
    function Cwrite_buf(req::FuseReq, ino::FuseIno, bufv::Ptr{FuseBufvec}, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            write_buf(req, ino, CStruct(bufv), off, CStruct(fi))          
        end
    end
    (@cfunction $Cwrite_buf Cvoid (FuseReq, FuseIno, Ptr{FuseBufvec}, Coff_t, Ptr{FuseFileInfo}))
end
# F_RETRIEVE_REPLY = 38
function Gretrieve_reply(retrieve_reply)
    function Cretrieve_reply(req::FuseReq, cookie::Ptr{Cvoid}, ino::FuseIno, off::Coff_t, bufv::Ptr{FuseBufvec})
        docall(req) do
            retrieve_reply(req, cookie, ino, off, CStruct(bufv))         
        end
    end
    (@cfunction $Cretrieve_reply Cvoid (FuseReq, Ptr{Cvoid}, FuseIno, Coff_t, Ptr{FuseBufvec}))
end
# F_FORGET_MULTI = 39
function Gforget_multi(forget_multi)
    function Cforget_multi(req::FuseReq, count::Csize_t, forgets::Ptr{FuseForgetData})
        docall(req) do
            forget_multi(req, count, CStruct{forgets})         
        end
    end
    (@cfunction $Cforget_multi Cvoid (FuseReq, Csize_t, Ptr{FuseForgetData}))
end
# F_FLOCK = 40
function Gflock(flock)
    function Cflock(req::FuseReq, ino::FuseIno, fi::Ptr{FuseFileInfo}, op::Cint)
        docall(req) do
            flock(req, ino, CStruct(fi), op)          
        end
    end
    (@cfunction $Cflock Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Cint))
end
# F_FALLOCATE = 41
function Gfallocate(fallocate)
    function Cfallocate(req::FuseReq, ino::FuseIno, mode::Cint, off::Coff_t, length::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            fallocate(req, ino, mode, off, length, CStruct(fi))         
        end
    end
    (@cfunction $Cfallocate Cvoid (FuseReq, FuseIno, Cint, Coff_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_READDIRPLUS = 42
function Greaddirplus(readdirplus)
    #, size_t size, off_t off, struct fuse_file_info *fi)
    function Creaddirplus(req::FuseReq, ino::FuseIno, size::Csize_t, off::Coff_t, fi::Ptr{FuseFileInfo})
        docall(req) do
            readdirplus(req, ino, size, off, CStruct(fi))          
        end
    end
    (@cfunction $Creaddirplus Cvoid (FuseReq, FuseIno, Csize_t, Coff_t, Ptr{FuseFileInfo}))
end
# F_COPY_FILE_RANGE = 43
function Gcopy_file_range(copy_file_range)
    function Ccopy_file_range(req::FuseReq, ino_in::FuseIno, off_in::Coff_t, fi_in::Ptr{FuseFileInfo}, ino_out::FuseIno, off_out::Coff_t, fi_out::Ptr{FuseFileInfo}, len::Csize_t, flags::Cint)
        docall(req) do
            copy_file_range(req, ino_in, off_in, CStruct(fi_in), ino_out, off_out, CStruct(fi_out), len, flags)         
        end
    end
    (@cfunction $Ccopy_file_range Cvoid (FuseReq, FuseIno, Coff_t, Ptr{FuseFileInfo}, FuseIno, Coff_t, Ptr{FuseFileInfo}, Csize_t, Cint))
end
# F_LSEEK = 44
function Glseek(lseek)
    function Clseek(req::FuseReq, ino::FuseIno, off::Coff_t, whence::Cint, fi::Ptr{FuseFileInfo})
        docall(req) do
            lseek(req, ino, off, whence, CStruct(fi))        
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
    ccall((:fuse_reply_buf, :libfuse3), Cint, (FuseReq, Ptr{UInt8}, Csize_t), req, buf, size)
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
    ccall((:fuse_reply_open, :libfuse3), Cint, (FuseReq, Ptr{FuseFileInfo}), req, fi)
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

# helper function to support readdir
function fuse_add_direntry(req::FuseReq, buf::AbstractVector{UInt8}, name::String, st::CStructAccess{Cstat}, off::Integer)
    bufsz = length(buf)
    ccall((:fuse_add_direntry, :libfuse3), Csize_t, (FuseReq, Ptr{UInt8}, Csize_t, Cstring, Ptr{Cstat}, Coff_t), req, buf, bufsz, name, st, off)
end

function fuse_add_direntry_plus(req::FuseReq, buf::AbstractVector{UInt8}, name::String, e::CStructAccess{FuseEntryParam}, off::Integer)
    bufsz = length(buf)
    ccall((:fuse_add_direntry_plus, :libfuse3), Csize_t, (FuseReq, Ptr{UInt8}, Csize_t, Cstring, Ptr{FuseEntryParam}, Coff_t), req, buf, bufsz, name, e, off)
end