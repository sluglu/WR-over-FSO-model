# WR-over-FSO-model
A MATLAB model for simulating White Rabbit (WR) synchronization in orbital scenarios using Free-Space Optics (FSO) communication behavior.

Components to be implemented : 
 - PTP/WR message exchange (MATLAB): Sync, Follow Up,
Delay Req, Delay Resp.
- Software clock model (MATLAB): Master/slave clocks with
configurable drift.
- Communication channel (MATLAB): Doppler and propagation
delay asymmetry modeling.
- WR PI loop (Simulink): Phase offset correction using a PI controller.
- PLL model for SyncE (Simulink): Frequency locking using a phase
comparator (simplified DDMTD) and low-pass filter.
- PPS alignment (MATLAB): Evaluation of final timing accuracy. 
