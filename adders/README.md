# Ripple-Carry Adder & Hierarchical CLA

## Ripple-Carry Adder (RC)

The RC adder utilizes a series of 1-bit full adders (fa) to perforom addition with carrys. 
We chain the carry output of one fa to the carry in of the next to propagate the carry to the following bits.

      Example:
      
            -------------               -------------               -------------               -------------         
            |        x  |-------- x(3)  |         x |-------- x(2)  |        x  |-------- x(1)  |        x  |-------- x(0)
            |        y  |-------- y(3)  |         y |-------- y(2)  |        y  |-------- y(1)  |        y  |-------- y(0)
    --------| cout  cin |_______________| cout  cin |_______________| cout  cin |_______________| cout  cin |-------- carry_in
    |       |    s      |               |    s      |               |    s      |               |    s      |
    |       -------------               -------------               -------------               -------------
    |            |                           |                           |                           |  
      carry_out s(3)                        s(2)                        s(1)                        s(0)
