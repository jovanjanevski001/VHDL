# Ripple-Carry Adder & Hierarchical CLA

## Ripple-Carry Adder (RC)

The RC adder utilizes 1-bit full adders that chains the carry output of one to the carry in of the next to propagate the carry to the following bits.

      Example: 
            x,y : 4-bit input
            cin : 1-bit input
            s : 4-bit output      
            cout : 1-bit output
      
            ---------               ---------               ---------               ---------         
            |       |               |       |               |       |               |       |
            |       |               |       |               |       |               |       |
            |       |               |       |               |       |               |       |
            |       |               |       |               |       |               |       |
            ---------               ---------               ---------               ---------
