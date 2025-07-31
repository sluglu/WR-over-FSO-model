# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module (include : oscillator model, L1 syntonization, offset correction)
- Node object (include timestamper, govern clock and fsm)
- noise profile submodule (for the clocks)
- PTP FSM module (include ptp fsm)
- experiment#1 : PTP offset error / asymetric delay STD (fast changing delay and delay asymetry)

Components to be implemented : 

- orbit_model :
    - cross-plane position function from orbital parameter
    - compute intercept from position function and t0
    - check LOS

- experiment#2 : offset error plot and mean with different orbital scenario

the sytem is modeled as perfect : - Perfect L1 syntonization (slave perfectly recover incoming frequency)
                                  - Timestamp are fractional (not limited to clock cycle resolution)
