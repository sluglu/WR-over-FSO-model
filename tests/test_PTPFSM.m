clear; clc;

%% Parameters
sim_duration = 10;     % seconds
dt = 0.001;             % time step
f0 = 125e6;
t0 = 0;
sync_interval = 0.1;
delay = 5e-3;

times = 0:dt:sim_duration;

%% Mock classes (minimal versions)

% Noisy profile
params_noisy = struct(...
    'delta_f0', 500, ...
    'alpha', 300, ...
    'sigma_rw', 1000, ...
    'sigma_jitter', 500 ...
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
master = MasterNode(clock_master, timestamper_master, MasterFSM(sync_interval));
slave  = SlaveNode(clock_slave,  timestamper_slave, SlaveFSM(), syntonizer);

%% Logs
slave_freq_log = nan(size(times));
ptp_offset_log = nan(size(times));
real_offset = nan(size(times));


%% Simulation loop
msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});

for i = 1:length(times)
    sim_time = times(i);
    % STEP master and slave
    [master, master_msgs] = master.step(sim_time);
    slave = slave.syntonize(master.clock.f);
    [slave, slave_msgs] = slave.step(sim_time);

    % ENQUEUE messages from master
    for j = 1:length(master_msgs)
        msg_queue(end+1) = struct(...
            'target', 'slave', ...
            'msg', master_msgs(j), ...
            'delivery_time', sim_time + delay);
    end

    % ENQUEUE messages from slave
    for j = 1:length(slave_msgs)
        msg_queue(end+1) = struct(...
            'target', 'master', ...
            'msg', slave_msgs(j), ...
            'delivery_time', sim_time + delay);
    end

    % DELIVER messages whose time has come
    to_deliver = [msg_queue.delivery_time] <= sim_time;
    for j = find(to_deliver)
        if strcmp(msg_queue(j).target, 'master')
            master = master.receive(msg_queue(j).msg);
        else
            slave = slave.receive(msg_queue(j).msg);
        end
    end
    % Remove delivered messages from queue
    msg_queue = msg_queue(~to_deliver);

    % Log
    slave_freq_log(i) = slave.clock.f;
    ptp_offset_log(i) = slave.fsm.last_offset;
    real_offset(i) = (slave.clock.phi - master.clock.phi) / (2*pi*f0);

    fprintf("t1 = %.9f | t2 = %.9f | t3 = %.9f | t4 = %.9f\n", slave.fsm.t1, slave.fsm.t2, slave.fsm.t3, slave.fsm.t4);
    fprintf("Offset = %.6f | Delay = %.6f\n", slave.fsm.last_offset, slave.fsm.last_delay);
end

%% Plot results
figure;
subplot(3,1,1);
plot(times, (slave_freq_log - 125e6));
xlabel('Time (s)');
ylabel('Slave freq offset (Hz)');
title('Syntonization - Frequency Offset');

subplot(3,1,2);
plot(times, ptp_offset_log, 'b', times, real_offset, 'r');
xlabel('Time (s)');
ylabel('Offset (s)');
title('PTP Offset vs Real Offset');
legend('PTP Offset', 'Real Offset');

subplot(3,1,3);
plot(times, real_offset - ptp_offset_log);
xlabel('Time (s)');
ylabel('Offset Error (s)');
title('PTP Offset Error');
