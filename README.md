# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock module
- L1_syntonizer module

Components to be implemented : 
- Node object (probably need rework)
- noise profile submodule (do i even want to use this ?)
- timestamper module (need rework : basic -> local ehanced or local + recovered ehanced)
- 3 info need to go between node : msg, frequency, fractional part of the phase when msg sended
- phase comparator (local vs recovered)
- PTP FSM module (bug : weird spike)
- offset calculation module (input timestamps, with medium solution child class : single-mode fiber; FSO, mmwawe, no noise beacuse numerical ?, output phase offset)
- offset and frequency correction module (input phase offset and clock, with noise profile ?, update clock)
- channel model :
    - doppler_shift (input phi and current time, add doppler, output phi)
    - delay (input tx time, output rx time)
    - calculate channel (calculate delay and doppler from given satellite scenario)

PTP message exchange govern every transmission.
every transmission go like this :
master or slave clock model -> timestamping -> channel model -> L1 syntonization -> timestamping (maybe L1 syntonization is continuous depending on the channel model)
and when t1, t2, t3 and t4 have been aquired by the slave, he does the offset calculation and correction.
