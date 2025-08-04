# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module
- Node object
- noise profile submodule (for the clocks)
- PTP FSM module
- experiment#1 : PTP offset error / asymetric delay STD (fast changing delay and delay asymetry)
- orbit model
- experiment#2 : offset error / time for given orbital scenario

Components to be implemented : 

- experiment#2 or #3 : multiple orbital scenario and/or sync_interval (parrallelize)


the sytem is modeled as perfect (white rabbit work perfectly and in this case how PTP react): 
- Perfect L1 syntonization (slave perfectly recover incoming frequency)
- Timestamp are fractional (not limited to clock cycle resolution)
