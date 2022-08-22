This folder contains the vhdl code for a generic width alu, along with a testbench to simulate functionality of the opcodes

NOTE: a top_level.vhd is included to test on the DE10-LITE. However the decoder7seg vhd files need to be added to the project.


    SEL                       OUTPUT                                                OVERFLOW (assume all operations are unsigned)                         
    0000      input1 + input2                                  ‘1’ if the sum is larger than the maximum number that can be written to output, ‘0’ otherwise   
    0001      input1 - input2                                  '0'                                                                                              
    0010      input1 * input2                                  ‘1’ if result is larger than the maximum number that can be written to output, ‘0’ otherwise     
    0011      input1 AND input2                                '0'                                                                                              
    0100      input1 OR input2                                 '0'                                                                                              
    0101      input1 XOR input2                                '0'                                                                                              
    0110      input1 NOR input2                                '0'                                                                                              
    0111      NOT input1                                       '0'                                                                                              
    1000      SHL input1 by 1-bit                              The high bit of input1 before the shift operation is performed                                   
    1001      SHR input1 by 1-bit                              '0'                                                                                              
    1010     *SWAP upper bits of input1 with lower bits*       '0'                                                                                              
    1011      REVERSE bits of input1                           '0'                                                                                              
    1100      NC                                               '0'                                                                                              
    1101      NC                                               '0'                                                                                              
    1110      NC                                               '0'                                                                                              
    1111      NC                                               '0'                                                                                              

* NOTE SEL = "1010": In the case of an odd width, use 1 extra bit from the high half. For example, 0101000 should become 0000101. *
