module ExampleFs

using ..FuseApi

function lookup(req::FuseReq, parent::FuseIno, name::String, entry::CStructAccess{FuseEntryParam})
    println("lookup(req, $parent, $name) called")
    name != "xxx" && return Base.UV_ENOENT
    entry.ino = 4711
    entry.attr_timeout = 0.0
    entry.entry_timeout = 1e19
    st = entry.attr
    st.ino = 4712
    st.mode = 0o777
    st.uid = 1003
    st.gid = 10000
    st.size = 4712
    return 0
end

function getattr(req::FuseReq, ino, fi::CStruct{FuseFileInfo}, st::CStructAccess{Cstat}, attr_to::Ref{Float64})
    println("getattr(req, $ino, ...) called")
    st.ino = ino
    st.mode = 0o777
    st.uid = 10003
    st.gid = 10000
    st.size = 42
    return 0
end

args = ["mountpoint", "-d", "-h", "-V", "-f" , "-s", "-o", "clone_fd", "-o", "max_idle_threads=5"]

run() = main_loop(args, @__MODULE__)

end # module ExampleFs