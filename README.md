# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module (include : oscillator model, L1 syntonization, offset correction)
- Node object (include timestamper, govern clock and fsm)
- noise profile submodule (for the clocks)
- PTP FSM module (include ptp fsm)
- experiment#1 : PTP offset error / delay STD (fast changing delay and delay asymetry)

Components to be implemented : 

- experiment#2 : offset accuracy / frequency sigma (doppler) ??
- experiment#3 : exp#1 and exp#2 in a color map ??

- channel model :
    - doppler_shift (input freq, current time, output freq)
    - delay (input tx time, current time, output rx time)
    - calculate channel (calculate delay and doppler from given satellite scenario and time vector, output two vector)

the sytem is modeled as perfect : - Perfect L1 syntonization (slave perfectly recover frequency)
                                  - Timestamp are fractional (not limited to clock cycle resolution, no need for phase comparator system)
