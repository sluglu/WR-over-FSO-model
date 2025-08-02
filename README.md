# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module
- Node object
- noise profile submodule (for the clocks)
- PTP FSM module
- experiment#1 : PTP offset error / asymetric delay STD (fast changing delay and delay asymetry)
- orbit model

Components to be implemented : 

- experiment#2 : offset error plot and mean with different orbital scenario

the sytem is modeled as perfect : - Perfect L1 syntonization (slave perfectly recover incoming frequency)
                                  - Timestamp are fractional (not limited to clock cycle resolution)
