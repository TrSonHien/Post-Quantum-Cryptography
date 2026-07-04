TESTNAME ?= test
TB_NAME  ?= test_bench
RADIX    ?= decimal
MEALY_FSM ?= 0

all: build run

all_wave: build run wave

all_cov: build_cov run_cov

drc:
	verilator --lint-only -Wall -f rtl.f

build:
	vlib work
	vmap work work
	vlog -f compile.f | tee compile.log

build_cov:
	vlib work
	vmap work work
	vlog +cover=bcesft -f compile.f
run:
	vsim -debugDB -l $(TESTNAME).log -voptargs=+acc -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;"

run_cov:
	vsim -coverage -l $(TESTNAME).log -c $(TB_NAME) -voptargs="+cover=bcesft" -assertdebug -do "coverage save -onexit $(TESTNAME).ucdb; log -r /*;run -all"

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &

gen_cov:
	mkdir -p coverage
	vcover merge IP.ucdb *.ucdb
	vcover report IP.ucdb -output coverage/summary_report.txt
	vcover report -zeros -details -code bcesft -annotate -All -codeAll IP.ucdb -output coverage/detail_report.txt

gen_html:
	mkdir -p coverage
	vcover merge IP.ucdb *.ucdb
	vcover report -zeros -details -code bcesft -annotate -testhitdataAll -html IP.ucdb

clean:
	rm -rf work
	rm -rf vsim.dbg
	rm -rf *.ini
	rm -rf *.log
	rm -rf log
	rm -rf *.wlf
	rm -rf transcript
	rm -rf *.ucdb
	rm -rf compile.log
	rm -rf coverage
	rm -rf covhtmlreport
