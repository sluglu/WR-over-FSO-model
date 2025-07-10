clear; clc;

%% Parameters
sim_duration = 10;     % seconds
dt = 0.01;             % time step
times = 0:dt:sim_duration;
f0 = 125e6;
t0 = 0;

%% Mock classes (minimal versions)

% Noisy profile
params_noisy = struct(...
    'delta_f0', 50, ...
    'alpha', 100, ...
    'sigma_rw', 500, ...
    'sigma_jitter', 20 ...
);

% Ideal profile
params_ideal = struct(...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'sigma_rw', 0, ...
    'sigma_jitter', 0 ...
);

%% INIT CLOCKS
np_noisy = NoiseProfile(params_noisy);
np_ideal = NoiseProfile(params_ideal);

clock_master = MasterClock(f0, t0, np_ideal);
clock_slave  = SlaveClock(f0, t0, np_noisy);

timestamper_master = Timestamper(np_noisy);
timestamper_slave = Timestamper(np_noisy);

syntonizer = L1Syntonizer(np_noisy);

%% Create nodes
master = MasterNode(clock_master, timestamper_master, MasterFSM());
slave  = SlaveNode(clock_slave,  timestamper_slave, SlaveFSM(), syntonizer);

%% Logs
slave_freq_log = zeros(size(times));
offset_log = nan(size(times));

%% Simulation loop
for i = 1:length(times)
    sim_time = times(i);

    % Master node step
    msgs_from_master = master.step(sim_time);

    % Route messages to slave
    for j = 1:length(msgs_from_master)
        slave.receive(msgs_from_master{j}, sim_time);
    end

    % Slave step (requires master's current frequency)
    rx_freq = master.clock.f;
    msgs_from_slave = slave.step(sim_time, rx_freq);

    % Route messages to master
    for j = 1:length(msgs_from_slave)
        master.receive(msgs_from_slave{j}, sim_time);
    end

    % Log
    slave_freq_log(i) = slave.clock.f;
    offset_log(i) = slave.fsm.last_offset;
end

%% Plot results
figure;
subplot(2,1,1);
plot(times, (slave_freq_log - 125e6) * 1e6);
xlabel('Time (s)');
ylabel('Slave freq offset (ppm)');
title('Syntonization - Frequency Offset');

subplot(2,1,2);
plot(times, offset_log * 1e9);
xlabel('Time (s)');
ylabel('Offset (ns)');
title('PTP Offset Correction');
