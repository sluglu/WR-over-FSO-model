# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock class
- noise profile class
- timestamper class

Components to be implemented : 
- L1 syntonization (input freq and doppler, add doppler, add noise profile (CDR,PLL,etc), output freq, with compensated and non-compensated child class)
- PTP message exchange (maybe with SimEvents ?)
- link delay model and offset calculation logic (input timestamps, with medium solution child class : single-mode fiber; FSO, mmwawe, no noise beacuse numerical ?, output phase offset)
- offset correction module (input phase offset and clock, with noise profile ?, update clock)
- channel model (input freq and maybe message, maybe with Satellite communication toolbox ? maybe simulating different modulation scheme, output freq and maybe message)

PTP message exchange govern every transmission.
every transmission go like this :
master or slave clock model -> timestamping -> channel model -> L1 syntonization -> timestamping (maybe L1 syntonization is continuous depending on the channel model)
and when t1, t2, t3 and t4 have been aquired by the slave, he does the offset calculation and correction.
