# Clock Divider and Clock Generator

This folder contains VHDL code to divide the clock of the DE10-LITE and generate the newly divided clock to drive whatever entities will need use of it.

The entities use generics so they are portable across any device, simply specify the clk_in_freq and clk_out_freq.
