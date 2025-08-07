# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module
- Node object
- noise profile submodule (for the clocks)
- PTP FSM module
- experiment#1 : PTP offset error / asymetric delay STD (fast changing delay and delay asymetry)
- orbit model

TODO : 

- test for offset correction
- experiment#2 : PTP + orbital scenario (all parameters should be exposed, TODO: offset correction and syntonization)

the sytem is modeled as perfect (white rabbit work perfectly and in this case how PTP react): 
- Perfect L1 syntonization (slave perfectly recover incoming frequency)
- Timestamp are fractional (not limited to clock cycle resolution)
