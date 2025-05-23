% Purpose: Test and visualize White Rabbit clock model behavior

clear; clc;

% === Parameters ===
nominal_freq = 125e6;   % Standard WR clock = 125 MHz
sim_duration = 10;      % total time = 10 s
drift_ppb = 100;        % slave clock drift = 100 ppb
Cumulative_Jitter_std = 5e-12;    % Cumulative jitter from the oscillator
measurement_jitter_std = 30e-12;  % Measurement for timestamping

sim_dt = 1e-3;                      % Simulation time step
correction_interval = 100e-3;       % Apply correction every 100 ms

% Create clocks
master = master_clock(nominal_freq);            % Ideal master
slave  = slave_clock(nominal_freq, drift_ppb, Cumulative_Jitter_std, measurement_jitter_std); % Drifted slave

% Simulation phases: [before SyncE, after SyncE, after offset correction, correction interval]
n_total = round(sim_duration / sim_dt);
n1 = round(n_total / 3);
n2 = round(n_total / 3);
n3 = n_total - n1 - n2;
ci = round(sim_duration / correction_interval);

% Data logging
time_axis = (0:n_total-1) * sim_dt;
time_error = zeros(1, n_total);        % in ns

% === Phase 1: BEFORE syntonization ===
u = 1;
while u < n1
    advance_clocks(master, slave, sim_dt);
    time_error(u) = 1e9 * (slave.get_time_raw() - master.get_time_raw());
    u = u + 1;
end

% === Phase 2: Apply syntonization ===

% SyncE approx
function syntonize(mc, sc)
    sc.frequency = mc.frequency;
end

u = n1;
slave.tick_callback = @(sc)syntonize(master, sc);
while u < n1 + n2
    % slave.drift_ppb = 0;
    % slave.apply_freq_correction(master.frequency - slave.frequency); % Simulate SyncE continuous syntonization
    advance_clocks(master, slave, sim_dt);
    time_error(u) = 1e9 * (slave.get_time_raw() - master.get_time_raw());
    u = u + 1;
end

% === Phase 3: Apply offset correction (WR-like) ===
u = n1 + n2;
while u < n1 + n2 + n3
    %slave.apply_freq_correction(master.frequency - slave.frequency); 
    if mod(u, ci) == 0
        offset_est = slave.get_time_raw() - master.get_time_raw();
        slave.apply_offset_correction(-offset_est); % Simulate WR offset correction every cycle
        %disp(u*sim_dt);
    end
    advance_clocks(master, slave, sim_dt);
    time_error(u) = 1e9 * (slave.get_time_raw() - master.get_time_raw());
    u = u + 1;
end


% === Plotting ===
figure;
window = n_total / 50;  % size of moving average window 125000 cycles = 1ms
smoothed_error = movmean(time_error, window);
plot(time_axis, time_error, 'LineWidth', 1.0); 
hold on;
plot(time_axis, smoothed_error, '--r', 'LineWidth', 1.5);
xlabel('Time [s]');
ylabel('Time Error [ns]');
title('Slave Time Error Relative to Master with (WR Clock Model Test)');
grid on;
xline(time_axis(n1-1), '--k', 'SyncE applied');
xline(time_axis(n1+n2-1), '--r', 'SyncE + Offset correction applied');
legend('Time error', 'Location', 'best');
legend('Time error', 'Moving average', 'Location', 'best');
