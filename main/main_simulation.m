clear; clc;

% --- Simulation Config ---
cycle_time = 1;                  % WR cycle every 1 s (the full PTP exchange must be contained in one cycle)
steps = 100;
drift_ppm = 80;                   % 50 ppm drift for slave
drift = drift_ppm * 1e-6;

% --- Init Clocks ---
master = master_clock(0);
slave  = slave_clock(0, drift, 0, 0);

% --- Delay Parameters (in s) ---
delays.sync           = 0.05;   % Propagation delay for Sync
delays.delayreq_send  = 0;   % Slave processing delay before sending Delay_Req
delays.delayreq_prop  = 0.05;   % Propagation delay for Delay_Req to reach master

% --- Logs ---
est_offset_log = zeros(1, steps);
time_log   = zeros(1, steps);
offset_log = zeros(1, steps);

% --- Simulation Loop ---
for k = 1:steps
    % Perform a full PTP exchange
    [offset, delay, real_offset, total_time, t1, t2, t3, t4, master, slave] = ptp_full_exchange(master, slave, delays);


    offset_log(k) = real_offset;

    est_offset_log(k) = offset;
    time_log(k)   = (k-1) + total_time;

    [master, slave] = advance_both_clocks(master,slave, cycle_time - total_time);

    
end

% --- Plot results ---
figure;
plot(time_log, est_offset_log, "--b");
hold on
plot(time_log, offset_log, "--r");
xlabel('Time (s)');
ylabel('s');
title('Estimated Offset vs Real Offset');
legend("Estimated Offset", "Real Offset");
grid on;