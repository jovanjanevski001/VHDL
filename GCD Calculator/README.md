# Greatest Common Denominator (GCD) Calculator

*** Before discussing the design, refer to gcd.txt for the pseudocode of the algorithm. ***

The GCD calculator was designed and synthesized using 3 different architectures:
* FSMD - 1-process model Finite State Machine with Datapath operations included in the FSM.
* FSM_D1 - An FSM (2-process model) that will control a separate Datapath (structural architecture) entity via control signals.
* FSM_D2 - Similiar to the FSM_D1, however this architecture uses one less subtractor, optimizing on resource consumption. To accomplish this, any extra control signal "sub_sel" is needed to be passed in the subtractor so we know which subtraction needs to occur.
* FSMD2 - 2-process model FSM with datapath operations included in the FSM.

Each architecture was tested using a testbench and simulations ran as expected. The RTL viewer of the synthesized design matches the schematics.

## FSMD 
Below is a pictorial representation of the FSMD developed in VHDL.

![Screenshot](gcd_fsmd.png)


## FSM + Datapath
The FSM shows the control flow logic, while the controller + datapath shows how each component is connected using the control flow logic from the FSM.

![Screenshot](gcd_fsm.png) 
![Screenshot](gcd_fsm_d.png)

Below is the FSM_D2 blockdiagram between the controller and datapath
![Screenshot](gcd_fsm_d2.png)
