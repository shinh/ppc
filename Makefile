AS := powerpc-linux-gnu-as
LD := powerpc-linux-gnu-ld

AS_SRCS := $(wildcard as/*.s)
AS_OBJS := $(AS_SRCS:.s=.o)
AS_EXES := $(AS_OBJS:as/%.o=exe/%)

C_SRCS := $(wildcard c/*.c)
C_ASMS := $(C_SRCS:.c=.s)
C_OBJS := $(C_ASMS:.s=.o)
C_EXES := $(C_OBJS:c/%.o=exe/%)

ML_SRCS := $(wildcard ml/*.ml)
ML_ASMS := $(ML_SRCS:.ml=.s)
ML_OBJS := $(ML_ASMS:.s=.o)
ML_EXES := $(ML_OBJS:ml/%.o=exe/%)
# TODO: float
ML_EXES := $(filter-out exe/float exe/inprod-loop exe/matmul exe/inprod exe/inprod-rec exe/matmul-flat exe/non-tail-if, $(ML_EXES))

RTL_SRCS := $(wildcard rtl/*.v)
RTL_SRCS := $(filter-out rtl/ram.v rtl/pll.v rtl/pll_ram.v, $(RTL_SRCS))

TB_SRCS := $(filter-out tb/cpu_test.v, $(wildcard tb/*_test.v))
TB_SIM_SRCS := $(wildcard tb/*_sim.v)
TB_EXES := $(TB_SRCS:.v=)

EXES := $(AS_EXES) $(C_EXES) $(ML_EXES)
BINS := $(EXES:=.bin)
EXE_STDOUTS := $(EXES:=.stdout)
EXE_TRACES := $(EXES:=.trace)
STDINS := $(wildcard $(EXES:exe/%=tb/%.stdin))

TB_CPU_SRCS := tb/cpu_test.v $(TB_SIM_SRCS)
TB_CPU_RAMS := $(BINS:exe/%.bin=tb/cpu_test.%.ram)
TB_CPU_EXES := $(TB_CPU_RAMS:.ram=)
TB_CPU_TRACE_EXES := $(TB_CPU_RAMS:tb/cpu_test.%.ram=tb/cpu_trace.%)
TB_CPU_TRACES := $(TB_CPU_TRACE_EXES:=.trace)
TB_CPU_STDOUTS := $(TB_CPU_EXES:=.stdout)
TB_CPU_OKS := $(TB_CPU_EXES:=.ok)
TB_CPU_OKS := $(filter-out $(AS_EXES:exe/%=tb/cpu_test.%.ok), $(TB_CPU_OKS))
TB_CPU_TRACE_OKS := $(TB_CPU_TRACES:.trace=.ok)
TB_CPU_TRACE_OKS := $(filter-out $(AS_EXES:exe/%=tb/cpu_trace.%.ok), $(TB_CPU_TRACE_OKS))
TB_CPU_STDINS := $(STDINS:tb/%.stdin=tb/cpu_test.%.stdin.hex)

TB_ALL_EXES := $(TB_EXES) $(TB_CPU_EXES)
TB_ALL_OUTS := $(TB_ALL_EXES:=.out)
TB_ALL_RESULTS :=  $(TB_ALL_OUTS:.out=.res)

ALL := $(ML_EXES) $(C_EXES) $(AS_EXES)
ALL += libc.s libc.o
ALL += $(TB_ALL_RESULTS)
ALL += $(TB_RAMS)
ALL += $(TB_CPU_OKS)
ALL += $(TB_CPU_TRACE_OKS)

IVERILOG := iverilog -g2005 -Wall -Wno-timescale -Irtl

all: $(ALL)

%.s: %.ml min-caml
	./min-caml $(basename $<)

%.s: %.c
	clang -MMD -O2 -Wno-builtin-requires-header -target powerpc -S -o $@ $<

%.s: %.S
	cpp $< > $@

%.o: %.s
	$(AS) -mregnames -o $@ $<

exe:
	mkdir -p $@

$(AS_EXES): exe/%: as/%.o ppc.lds | exe
	$(LD) -o $@ $< -Tppc.lds

$(C_EXES): exe/%: c/%.o libc.o ppc.lds | exe
	$(LD) -o $@ $< libc.o -Tppc.lds

$(ML_EXES): exe/%: ml/%.o libmincaml.o mincamlstub.o libc.o ppc.lds | exe
	$(LD) -o $@ $< libmincaml.o mincamlstub.o libc.o -Tppc.lds

$(BINS): %.bin: %
	objcopy -I elf32-big -O binary $< $@

$(TB_EXES): %: %.v $(RTL_SRCS) $(TB_SIM_SRCS)
	$(IVERILOG) $(RTL_SRCS) $(TB_SIM_SRCS) $< -o $@

define stdin-impl
$(if $1,$2$1$3)
endef

define stdin
$(call stdin-impl,$(wildcard $1),$2,$3)
endef

define run-iverilog
$(IVERILOG) -DTEST -DRAM=\"$<\" -DSTDIN=\"tb/cpu_test.$*.stdin.hex\" $1 $(TB_CPU_SRCS) $(RTL_SRCS) -o $@
endef

$(TB_CPU_STDINS): tb/cpu_test.%.stdin.hex: tb/%.stdin ./bin2hex.rb
	./bin2hex.rb $< > $@

%.stdin.hex:
	./bin2hex.rb /dev/null > $@

$(TB_CPU_EXES): tb/cpu_test.%: tb/cpu_test.%.ram tb/cpu_test.%.stdin.hex $(TB_CPU_SRCS) $(RTL_SRCS) $(TB_RAMS)
	$(call run-iverilog)

$(TB_CPU_TRACE_EXES): tb/cpu_trace.%: tb/cpu_test.%.ram tb/cpu_test.%.stdin.hex $(TB_CPU_SRCS) $(RTL_SRCS) $(TB_RAMS)
	$(call run-iverilog, -DTRACE=1)

define run-verilog-sim
$< | grep -v ': \$$readmemh'
endef

$(TB_ALL_OUTS): %.out: %
	$(run-verilog-sim) > $@.tmp && mv $@.tmp $@

$(TB_CPU_TRACES): %.trace: % trace_filter.rb
	$(run-verilog-sim) | ./trace_filter.rb > $@.tmp && mv $@.tmp $@

define run-diff
@if diff -uN $1 $2 > $@.tmp; then \
  echo PASS: "$*($3)"; \
  mv $@.tmp $@; \
else \
  echo FAIL: "$*($3)"; \
  cat $@.tmp; \
fi
endef

$(TB_ALL_RESULTS): %.res: %.out
#	$(call run-diff,$*.good,$<,test)

$(TB_CPU_RAMS): tb/cpu_test.%.ram: exe/%.bin ./bin2hex.rb
	./bin2hex.rb $< > $@

$(TB_CPU_STDOUTS): %.stdout: %.out filter_stdout.rb
	./filter_stdout.rb $< > $@.tmp && mv $@.tmp $@

$(TB_CPU_OKS): tb/cpu_test.%.ok: exe/%.stdout tb/cpu_test.%.stdout
	$(call run-diff,exe/$*.stdout,tb/cpu_test.$*.stdout,stdout)

$(TB_CPU_TRACE_OKS): tb/cpu_trace.%.ok: exe/%.trace tb/cpu_trace.%.trace
	$(call run-diff,exe/$*.trace,tb/cpu_trace.$*.trace,trace)

$(EXE_STDOUTS): exe/%.stdout: exe/% $(STDINS) psim
	./psim -e linux $< $(call stdin,tb/$*.stdin,<) > $@ || true

$(EXE_TRACES): exe/%.trace: exe/% $(STDINS) psim trace_filter.rb
	./psim -e linux -t pc -t regs $< $(call stdin,tb/$*.stdin,<) | ./trace_filter.rb > $@ || true

-include c/*.d

.SUFFIXES:
