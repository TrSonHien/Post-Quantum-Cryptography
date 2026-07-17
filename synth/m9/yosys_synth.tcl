# M9 generic full-top synthesis baseline. No mapped area or timing is implied
# unless a real technology library is explicitly added by a later flow.
read_verilog -sv -DSYNTHESIS -Irtl/common -f synth/m9/rtl.f
hierarchy -check -top mlkem768_top
proc
opt
fsm
opt
memory
opt
techmap
opt
stat
tee -o synth/m9/reports/mlkem768_top_stat.rpt stat
write_json synth/m9/reports/mlkem768_top_generic.json
