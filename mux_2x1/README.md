This folder contains the source code and testbench for a 2x1 multiplexer. 

NOTE: This 2x1 MUX will be used to structurally create larger MUXES in the future.
      i.e. a 4x1 MUX will just be 3 smaller 2x1 MUXES chained accordingly...
      
  
                                                                   TRUTH TABLE (EXAMPLE: in1, in2 are 1 bit)
                                                                           
                       2x1 MUX Diagram:                                   in1 | in2 | sel   |   output
                                                                           0     0     0    |     0
                          ________                                         0     0     1    |     0
            n            |        \                                        0     1     0    |     0
    in1 ____/___________ |         \                                       0     1     1    |     1
                         |   2x1    \      n                               1     0     0    |     1
            n            |   MUX     |_____/______ output                  1     0     1    |     0
    in2 ____/___________ |          /                                      1     1     0    |     1
                         |         /                                       1     1     1    |     1
                         |________/
                             |
                             |
                             |
                            sel
