CFLAGS  += -g
JL_SHARE = $(shell julia -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)
JULIA = $(HOME)/julia/julia

all: libmtcb.so

libmtcb.so: libmtcb.o
	gcc $(CFLAGS) -shared -o libmtcb.so libmtcb.o

clean:
	rm -f *.o *.so TTY

run: libmtcb.so callmtcb.jl
	$(JULIA) --startup-file=no callmtcb.jl

debug: libmtcb.so callmtcb.jl mtcb.debug TTY
	gdb -tui -x mtcb.debug -ex 'tty TTY' -ex r \
		--args $(JULIA) --startup-file=no callmtcb.jl
	rm -f TTY

TTY:
	ln -sf $$(gterm) TTY

