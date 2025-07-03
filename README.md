# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock class
- noise profile class
- timestamper class
- L1_syntonizer class

Components to be implemented : 
- PTP message exchange (maybe with SimEvents ?)
- link delay model and offset calculation logic (input timestamps, with medium solution child class : single-mode fiber; FSO, mmwawe, no noise beacuse numerical ?, output phase offset)
- offset correction module (input phase offset and clock, with noise profile ?, update clock)
- channel model :
    - doppler_shift (input phi and current time, add doppler, output phi)
    - delay (input tx time, output rx time)
    - calculate channel (calculate delay and doppler from given satellite scenario)

PTP message exchange govern every transmission.
every transmission go like this :
master or slave clock model -> timestamping -> channel model -> L1 syntonization -> timestamping (maybe L1 syntonization is continuous depending on the channel model)
and when t1, t2, t3 and t4 have been aquired by the slave, he does the offset calculation and correction.
