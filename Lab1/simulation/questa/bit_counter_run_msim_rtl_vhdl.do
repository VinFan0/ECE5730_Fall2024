transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {/home/ryan/OneDrive/Fall_2024/Reconfigurable/Labs/Lab0/bit_counter.vhd}

