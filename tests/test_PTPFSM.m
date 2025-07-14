clear; clc;

%% Parameters
sim_duration = 2;     % seconds
dt = 0.001;             % time step
f0 = 125e6;
t0 = 0;
sync_interval = 0.1;
delay = 10e-3;
dtx = 0;
drx = 0;

times = 0:dt:sim_duration;

%% Mock classes (minimal versions)

% Noisy profile
params_noisy = struct(...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'sigma_rw', 0, ...
    'sigma_jitter', 0 ...
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
% slave_freq_log = nan(size(times));
% ptp_delay_log = nan(size(times));
% ptp_offset_log = nan(size(times));
% real_offset = nan(size(times));


%% Simulation loop
msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});
i = 1;
sim_time = t0;

while sim_time < sim_duration
    times(i) = sim_time;
    % STEP master and slave
    [master, master_msgs] = master.step(sim_time);
    slave = slave.syntonize(master.clock.f);
    [slave, slave_msgs] = slave.step(sim_time);

    % ENQUEUE messages from master
    for j = 1:length(master_msgs)
        msg_queue(end+1) = struct(...
            'target', 'slave', ...
            'msg', master_msgs(j), ...
            'delivery_time', sim_time + delay + drx + dtx*j);
    end

    % ENQUEUE messages from slave
    for j = 1:length(slave_msgs)
        msg_queue(end+1) = struct(...
            'target', 'master', ...
            'msg', slave_msgs(j), ...
            'delivery_time', sim_time + delay + drx + dtx*j);
    end

    % DELIVER messages whose time has come
    to_deliver = [msg_queue.delivery_time] == sim_time;
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
    ptp_delay_log(i) = slave.fsm.last_delay;
    ptp_offset_log(i) = slave.fsm.last_offset;
    real_offset(i) = (slave.clock.phi - master.clock.phi) / (2*pi*f0);

    %fprintf("t1 = %.9f | t2 = %.9f | t3 = %.9f | t4 = %.9f\n", slave.fsm.t1, slave.fsm.t2, slave.fsm.t3, slave.fsm.t4);
    %fprintf("Offset = %.6f | Delay = %.6f\n", slave.fsm.last_offset, slave.fsm.last_delay);
    
    next_step = dt;
    max_next_sim_time = min([msg_queue.delivery_time]);
    max_dt = max_next_sim_time - sim_time;
    if max_dt <= dt
        next_step = max_dt;
    end
    
    sim_time = sim_time + next_step;
    i = i + 1;
end

%% Plot results
figure;

freq_error = slave_freq_log - 125e6;

subplot(3,1,1);
plot(times, freq_error);
xlabel('Time (s)');
ylabel('Slave Frequency Error (Hz)');
title('Syntonization - Frequency Error');

delay_error = (delay + drx+ dtx) - ptp_delay_log;

subplot(3,1,2);
plot(times, delay_error);
xlabel('Time (s)');
ylabel('Delay Error(s)');
title('PTP Delay Error');

off_error = real_offset - ptp_offset_log;

subplot(3,1,3);
plot(times, off_error);
xlabel('Time (s)');
ylabel('Offset Error (s)');
title('PTP Offset Error');

%% METRICS
% Phase Error
mean_freq_err = mean(freq_error);
std_freq_err  = std(freq_error);

mean_delay_err = mean(delay_error, "omitmissing");
std_delay_err  = std(delay_error, "omitmissing");

mean_off_err = mean(off_error, "omitmissing");
std_off_err  = std(off_error, "omitmissing");

% --- Console Output ---
fprintf('\n--- Error Statistics ---\n');
fprintf('Frequency Error    : Mean = %.3e Hz, Std = %.3e Hz\n', mean_freq_err, std_freq_err);
fprintf('Delay Error  : Mean = %.3e s, Std = %.3e s\n', mean_delay_err, std_delay_err);
fprintf('Offset Error  : Mean = %.3e s, Std = %.3e s\n', mean_off_err, std_off_err);
