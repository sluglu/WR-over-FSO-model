# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components implemented :
- clock class
- noise profile class

Components to be implemented : 
- timestamping (with noise profile for measurment noise (DDMTD,timestamping module,etc), coarse and fine, maybe a timestamper class with presice and coarse child class)
- L1 syntonization (input freq and doppler, add doppler, add noise profile (CDR,PLL,etc), output freq, with compensated and non-compensated child class)
- PTP message exchange (maybe with SimEvents ?)
- link delay model and offset calculation logic (with medium solution child class : single-mode fiber; FSO, mmwawe, no noise beacuse numerical ?)
- offset correction module (with noise profile ?)
- channel model (maybe with Satellite communication toolbox ? maybe simulating modulation scheme)

PTP message exchange govern every transmission.
every transmission go like this :
master or slave clock model -> timestamping -> channel model -> L1 syntonization -> timestamping (maybe L1 syntonization is continuous depending on the channel model)
and when t1, t2, t3 and t4 have been aquired by the slave, he does the offset calculation and correction.
