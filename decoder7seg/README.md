This folder contains the vhdl code for the 7seg displays on the DE-10 LITE board. A testbench is also included to simulate the design before synthesis.

           7SEG DISPLAY:                     Truth Table:                     ***** NOTE: The 7SEGs used on the DE10-LITE are all driven active low. *****
                                              
        __0___                            INPUT   |    OUTPUT
       |      |                           0000    |    1000000                NOTE: The output's MSB corresponds with 6 on the 7SEG display. 
     5 |      | 1                         0001    |    1111001                      MSB-1 will be 5, and so on until you reach the LSB of output.
       |__6___|                           0010    |    0100100
       |      |                           0011    |    0110000
     4 |      | 2   7                     0100    |    0011001                
       |______|     o  <- DP              0101    |    0010010
          3                               0110    |    0000010
                                          0111    |    1111000
                                          1000    |    0000000
                                          1001    |    0011000
                                          1010    |    0001000
                                          1011    |    0000011
                                          1100    |    0100111
                                          1101    |    0100001
                                          1110    |    0000110
                                          1111    |    0001110
