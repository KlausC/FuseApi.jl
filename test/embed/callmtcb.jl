
module Testcb
    f1() = println("called f1()")
    f2() = exit(99)
    cf1 = @cfunction f1 Cvoid ()
    cf2 = @cfunction f2 Cvoid ()

    push!(Base.DL_LOAD_PATH, pwd())
    dl = Base.Libc.dlopen("libmtcb")
    dls = Base.Libc.Libdl.dlsym(dl, :cb_setup)
    ccall(dls, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cf1, cf2)
end

