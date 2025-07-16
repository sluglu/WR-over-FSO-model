# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module (include : oscillator model, L1 syntonization, offset correction)
- Node object (include timestamper, govern clock and fsm)
- noise profile submodule (for the clocks)
- PTP FSM module (include ptp fsm)

Components to be implemented : 

- bug#1 : convergence detection don't working test_PTPFSM.m
- channel model :
    - doppler_shift (input freq, current time, output freq)
    - delay (input tx time, current time, output rx time)
    - calculate channel (calculate delay and doppler from given satellite scenario and time vector, output two vector)

the sytem is modeled as perfect : - Perfect L1 syntonization (slave perfectly recover frequency)
                                  - Timestamp are fractional (not limited to clock cycle resolution, no need for phase comparator system)
