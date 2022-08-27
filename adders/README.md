# Ripple-Carry Adder & Hierarchical CLA

## Ripple-Carry Adder (RC)

The RC adder utilizes a series of 1-bit full adders (fa) to perforom addition with carrys. 
We chain the carry output of one fa to the carry in of the next to propagate the carry to the following bits.

      Example:
      
            ---------               ---------               -------------               -------------         
            |       |               |       |               |        x  |               |        x  | 
            |       |               |       |               |        y  |               |        y  |
            |       |               |       |               |       cin |---------------| cout  cin |
            |       |               |       |               |           |               |    s      |
            ---------               ---------               -------------               -------------
