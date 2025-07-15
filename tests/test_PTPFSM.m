clear; clc;

%% Parameters
sim_duration = 2;     % seconds
dt = 0.00001;             % time step
f0 = 125e6;
t0 = 0;
sync_interval = 0.1;
delay = 10e-3;
dtx = 2e-6;
drx = 1e-6;

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

%timestamper_master = Timestamper(np_noisy); 
%timestamper_slave = Timestamper(np_noisy);

timestamper_master = Timestamper(); 
timestamper_slave = Timestamper();

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
ylabel('Frequency Error (Hz)');
title('Syntonization - Frequency Error');

delay_error = (delay + drx + dtx) - ptp_delay_log;

subplot(3,1,2);
plot(times, delay_error);
xlabel('Time (s)');
ylabel('Delay Error (s)');
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

% clear; clc;
% 
% %% Parameters - Much higher resolution
% sim_duration = 2;       % seconds
% dt = 1e-6;             % 1 microsecond resolution (was 1ms!)
% f0 = 125e6;
% t0 = 0;
% sync_interval = 0.1;
% network_delay = 10e-3;  % 10ms network delay
% dtx = 0;               % transmission delay
% drx = 0;               % reception delay
% 
% times = 0:dt:sim_duration;
% 
% %% Ideal noise profiles for debugging
% params_ideal = struct(...
%     'delta_f0', 0, ...
%     'alpha', 0, ...
%     'sigma_rw', 0, ...
%     'sigma_jitter', 0 ...
% );
% 
% %% INIT CLOCKS
% np_ideal = NoiseProfile(params_ideal);
% 
% clock_master = MasterClock(f0, t0, np_ideal);
% clock_slave  = SlaveClock(f0, t0, np_ideal);
% 
% timestamper_master = Timestamper(np_ideal); 
% timestamper_slave = Timestamper(np_ideal);
% 
% syntonizer = L1Syntonizer(np_ideal);
% 
% %% Create nodes
% master = MasterNode(clock_master, timestamper_master, MasterFSM(sync_interval));
% slave  = SlaveNode(clock_slave,  timestamper_slave, SlaveFSM(), syntonizer);
% 
% %% Enhanced logging
% log_size = length(times);
% slave_freq_log = nan(1, log_size);
% ptp_delay_log = nan(1, log_size);
% ptp_offset_log = nan(1, log_size);
% real_offset_log = nan(1, log_size);
% master_time_log = nan(1, log_size);
% slave_time_log = nan(1, log_size);
% 
% %% Simulation loop with event-driven message handling
% msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});
% i = 1;
% sim_time = t0;
% 
% % Add debug flag
% debug_messages = false;
% 
% fprintf('Starting PTP simulation...\n');
% fprintf('Network delay: %.3f ms\n', network_delay * 1000);
% fprintf('Simulation timestep: %.1f μs\n', dt * 1e6);
% 
% while sim_time <= sim_duration && i <= log_size
%     current_time = times(i);
% 
%     % DELIVER messages whose time has come
%     delivered_any = false;
%     to_deliver = abs([msg_queue.delivery_time] - current_time) < dt/2;
% 
%     for j = find(to_deliver)
%         delivered_any = true;
%         if strcmp(msg_queue(j).target, 'master')
%             master = master.receive(msg_queue(j).msg);
%             if debug_messages
%                 fprintf('%.6f: Master received %s\n', current_time, msg_queue(j).msg.type);
%             end
%         else
%             slave = slave.receive(msg_queue(j).msg);
%             if debug_messages
%                 fprintf('%.6f: Slave received %s\n', current_time, msg_queue(j).msg.type);
%             end
%         end
%     end
% 
%     % Remove delivered messages
%     msg_queue = msg_queue(~to_deliver);
% 
%     % STEP nodes (only advance time, don't process messages yet)
%     [master, master_msgs] = master.step(current_time);
% 
%     % Perfect frequency synchronization for testing PTP timing only
%     slave = slave.syntonize(master.clock.f);
%     [slave, slave_msgs] = slave.step(current_time);
% 
%     % ENQUEUE new messages from master
%     for j = 1:length(master_msgs)
%         delivery_time = current_time + network_delay + drx + dtx*j;
%         msg_queue(end+1) = struct(...
%             'target', 'slave', ...
%             'msg', master_msgs{j}, ...
%             'delivery_time', delivery_time);
% 
%         if debug_messages
%             fprintf('%.6f: Master sent %s, will arrive at %.6f\n', ...
%                 current_time, master_msgs{j}.type, delivery_time);
%         end
%     end
% 
%     % ENQUEUE new messages from slave
%     for j = 1:length(slave_msgs)
%         delivery_time = current_time + network_delay + drx + dtx*j;
%         msg_queue(end+1) = struct(...
%             'target', 'master', ...
%             'msg', slave_msgs{j}, ...
%             'delivery_time', delivery_time);
% 
%         if debug_messages
%             fprintf('%.6f: Slave sent %s, will arrive at %.6f\n', ...
%                 current_time, slave_msgs{j}.type, delivery_time);
%         end
%     end
% 
%     % Log data
%     slave_freq_log(i) = slave.clock.f;
%     ptp_delay_log(i) = slave.fsm.last_delay;
%     ptp_offset_log(i) = slave.fsm.last_offset;
% 
%     % Calculate true offset based on phase difference
%     master_phase = master.clock.phi;
%     slave_phase = slave.clock.phi;
%     real_offset_log(i) = (slave_phase - master_phase) / (2*pi*f0);
% 
%     master_time_log(i) = master_phase / (2*pi*f0);
%     slave_time_log(i) = slave_phase / (2*pi*f0);
% 
%     i = i + 1;
%     sim_time = current_time + dt;
% end
% 
% % Trim logs to actual size
% actual_size = i - 1;
% times = times(1:actual_size);
% slave_freq_log = slave_freq_log(1:actual_size);
% ptp_delay_log = ptp_delay_log(1:actual_size);
% ptp_offset_log = ptp_offset_log(1:actual_size);
% real_offset_log = real_offset_log(1:actual_size);
% 
% %% Enhanced plotting
% figure('Position', [100 100 1400 1000]);
% 
% % Frequency error
% freq_error = slave_freq_log - f0;
% subplot(3,1,1);
% plot(times, freq_error, 'b-', 'LineWidth', 1);
% xlabel('Time (s)');
% ylabel('Slave Frequency Error (Hz)');
% title('Syntonization - Frequency Error');
% grid on;
% 
% % Delay error
% expected_delay = network_delay + drx + dtx;
% delay_error = expected_delay - ptp_delay_log;
% 
% subplot(3,1,2);
% plot(times, delay_error * 1e9, 'r-', 'LineWidth', 1);
% xlabel('Time (s)');
% ylabel('Delay Error (ns)');
% title('PTP Delay Error');
% grid on;
% ylim_delay = max(abs(delay_error(~isnan(delay_error)))) * 1e9;
% if ylim_delay > 0
%     ylim([-ylim_delay*1.1, ylim_delay*1.1]);
% end
% 
% % Offset error
% offset_error = real_offset_log - ptp_offset_log;
% 
% subplot(3,1,3);
% plot(times, offset_error * 1e9, 'g-', 'LineWidth', 1);
% xlabel('Time (s)');
% ylabel('Offset Error (ns)');
% title('PTP Offset Error');
% grid on;
% ylim_offset = max(abs(offset_error(~isnan(offset_error)))) * 1e9;
% if ylim_offset > 0
%     ylim([-ylim_offset*1.1, ylim_offset*1.1]);
% end
% 
% sgtitle('PTP Performance Analysis (High Resolution)');
% 
% %% Enhanced statistics
% % Remove NaN values for statistics
% valid_freq = ~isnan(freq_error);
% valid_delay = ~isnan(delay_error);
% valid_offset = ~isnan(offset_error);
% 
% if sum(valid_freq) > 0
%     mean_freq_err = mean(freq_error(valid_freq));
%     std_freq_err = std(freq_error(valid_freq));
% else
%     mean_freq_err = NaN; std_freq_err = NaN;
% end
% 
% if sum(valid_delay) > 0
%     mean_delay_err = mean(delay_error(valid_delay));
%     std_delay_err = std(delay_error(valid_delay));
%     max_delay_err = max(abs(delay_error(valid_delay)));
% else
%     mean_delay_err = NaN; std_delay_err = NaN; max_delay_err = NaN;
% end
% 
% if sum(valid_offset) > 0
%     mean_offset_err = mean(offset_error(valid_offset));
%     std_offset_err = std(offset_error(valid_offset));
%     max_offset_err = max(abs(offset_error(valid_offset)));
% else
%     mean_offset_err = NaN; std_offset_err = NaN; max_offset_err = NaN;
% end
% 
% % Enhanced console output
% fprintf('\n=== PTP PERFORMANCE ANALYSIS ===\n');
% fprintf('Simulation parameters:\n');
% fprintf('  - Duration: %.1f s\n', sim_duration);
% fprintf('  - Time step: %.1f μs\n', dt * 1e6);
% fprintf('  - Network delay: %.3f ms\n', network_delay * 1000);
% fprintf('  - Sync interval: %.1f ms\n', sync_interval * 1000);
% 
% fprintf('\nResults:\n');
% fprintf('Frequency Error: Mean = %.3e Hz, Std = %.3e Hz\n', mean_freq_err, std_freq_err);
% fprintf('Delay Error   : Mean = %.3e s (%.1f ns), Std = %.3e s (%.1f ns), Max = %.1f ns\n', ...
%     mean_delay_err, mean_delay_err*1e9, std_delay_err, std_delay_err*1e9, max_delay_err*1e9);
% fprintf('Offset Error  : Mean = %.3e s (%.1f ns), Std = %.3e s (%.1f ns), Max = %.1f ns\n', ...
%     mean_offset_err, mean_offset_err*1e9, std_offset_err, std_offset_err*1e9, max_offset_err*1e9);
% 
% % Check for convergence
% if sum(valid_offset) > 10
%     final_offset_err = offset_error(valid_offset);
%     final_10_percent = final_offset_err(end-floor(length(final_offset_err)*0.1):end);
%     final_stability = std(final_10_percent);
%     fprintf('Final 10%% stability: %.1f ns RMS\n', final_stability*1e9);
% end
