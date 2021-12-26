# FuseApi

[![Build Status](https://github.com/KlausC/FuseApi.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/KlausC/FuseApi.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/KlausC/FuseApi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/KlausC/FuseApi.jl)

## Purpose

The FUSE Api is a C-library (libfuse3) on Linux and similar systems, which support the FUSE kernel feature.
This Filesystem in User space option allows to implement the internals of a file system in a process, which
runs in user space (not in a kernel module).

This package is designed to support the low level operations in Julia.

## Installation

]activate MyFileSystem

]add FuseApi

## Usage

### Setup functions

Ther is only one setup function `fuse_main_loop(args, module[, user_data])`, which delivers commandline arguments
of the mount process, the name of the implementing module, which defines the callbacks, and an optional user data
object.

### Callback functions

For each of the (44) callback functions defined by the library, an implementation may be provided as an exported
function of a separate module (named `MyFileSystem` in this description).

The names and signatures are fixed and can be derived from file [fuse-bridge.jl](https://github.com/KlausC/FuseApi.jl/src/fusebridge.jl).
The callback functions shall return 0 after calling one of the fuse_reply functions, or a error number, as accessible by `Base.UV_E...`.
These error numbers are typically directly passed to the system functions which evoked the callback.

Each callback function requires a call to a specific reply function in the success case. Which one is documented here:
In the error case, the framework calls a `fuse_reply_err(req, errno)` from the returned error code.

The user data object can be accessed with `fuser_user_data(req)` from the callback functions, which have the `req::FuseReq` argument
and from special arguments in `init` and `destroy`.

    module MyFileSystem
    using FuseApi

    # callbacks
    export lookup
    function lookup(req::FuseReq, parent::FuseIno, name::String)

        return fuse_reply_err(req, errno)

        fuse_reply_stat(req, ...)
    end

    # setup
    main_loop(Base.ARGS, MyFileSystem, user_data)

    end # module

## Links

The documentation of the C-library is found here: [libfuse3-doc](http://libfuse.github.io/doxygen/index.html).
