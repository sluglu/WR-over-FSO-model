clear; clc;


function delay_error_all = run_sim_loop(delay_std)
    %% Parameters
    sim_duration = 10;     % seconds
    dt = 0.001;            % time step
    f0 = 125e6;
    t0 = 0;
    sync_interval = 1;
    delay_a = 10e-3;
    dtx = 2e-3;
    drx = 1e-3;
    
    convergence_threshold = 1e-9;
    
    %% Noise profiles
    params_noisy = struct(...
        'delta_f0', 0, ...
        'alpha', 0, ...
        'sigma_rw', 0, ...
        'sigma_jitter', 0 ...
    );
    
    params_ideal = struct(...
        'delta_f0', 0, ...
        'alpha', 0, ...
        'sigma_rw', 0, ...
        'sigma_jitter', 0 ...
    );
    
    %% Initialize clocks
    np_noisy = NoiseProfile(params_noisy);
    np_ideal = NoiseProfile(params_ideal);
    
    clock_master = MasterClock(f0, t0, np_ideal);
    clock_slave  = SlaveClock(f0, t0, np_noisy);  % 10s initial offset
    
    %% Create nodes
    master = MasterNode(clock_master, MasterFSM(sync_interval));
    slave  = SlaveNode(clock_slave, SlaveFSM());
    
    %% Simulation setup
    msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});
    times = [];
    slave_freq_log = [];
    ptp_delay_log = [];
    ptp_offset_log = [];
    real_offset = [];

%% Simulation loop


    sim_time = t0;
    i = 1;
    sync_event_times = [];  % Track when sync events complete
    
    while sim_time < sim_duration
        times(i) = sim_time;
        
        % Step master and slave nodes
        [master, master_msgs] = master.step(sim_time);
        [slave, slave_msgs] = slave.step(sim_time, master.clock.f);
    
        % Check if slave just completed a sync
        if slave.fsm.just_synced
            sync_event_times(end+1) = sim_time;
        end
    
        delay = delay_a + randn * delay_std;
    
        % Enqueue messages from master
        for j = 1:length(master_msgs)
            msg_queue(end+1) = struct(...
                'target', 'slave', ...
                'msg', master_msgs{j}, ...
                'delivery_time', sim_time + delay + drx + dtx*j);
        end
    
        % Enqueue messages from slave
        for j = 1:length(slave_msgs)
            msg_queue(end+1) = struct(...
                'target', 'master', ...
                'msg', slave_msgs{j}, ...
                'delivery_time', sim_time + delay + drx + dtx*j);
        end
    
        % Deliver messages whose time has come
        if ~isempty(msg_queue)
            to_deliver = [msg_queue.delivery_time] <= sim_time;
            for j = find(to_deliver)
                if strcmp(msg_queue(j).target, 'master')
                    master = master.receive(msg_queue(j).msg, msg_queue(j).delivery_time);
                else
                    slave = slave.receive(msg_queue(j).msg, msg_queue(j).delivery_time);
                end
            end
            % Remove delivered messages from queue
            msg_queue = msg_queue(~to_deliver);
        end
    
        % Log data
        slave_freq_log(i) = slave.clock.f;
        ptp_delay_log(i) = slave.fsm.last_delay;
        ptp_offset_log(i) = slave.fsm.last_offset;
        
        % Calculate real offset between clocks
        master_time = master.clock.phi / (2*pi*f0);
        slave_time = slave.clock.phi / (2*pi*f0);
        real_offset(i) = slave_time - master_time;
        
        % Determine next simulation time
        if ~isempty(msg_queue)
            next_msg_time = min([msg_queue.delivery_time]);
            sim_time = min(sim_time + dt, next_msg_time);
        else
            sim_time = sim_time + dt;
        end
        
        i = i + 1;
    end

    %% Calculate errors (exclude initial transient period)
    
    
    first_sync_idx = find(~isnan(ptp_offset_log), 1);
    if ~isempty(first_sync_idx)
        % Find when system has converged (after first major correction)
        convergence_idx = first_sync_idx;
        
        % Look for when offset becomes small and stays there
        for idx = first_sync_idx:length(ptp_offset_log)
            if abs(ptp_offset_log(idx)) < convergence_threshold
                convergence_idx = idx;
                break;
            end
        end
        
        % Use data after convergence for statistics
        %analysis_start = min(convergence_idx + 50, length(times));  % Allow 50 samples after convergence
        analysis_start = convergence_idx + 50;  % Allow 50 samples after convergence
        
        if analysis_start < length(times)
            analysis_indices = analysis_start:length(times);
            
            freq_error = slave_freq_log(analysis_indices) - 125e6;
            delay_error = (delay + drx + dtx) - ptp_delay_log(analysis_indices);
            off_error = real_offset(analysis_indices) - ptp_offset_log(analysis_indices);
            
            % Remove NaN values
            freq_error = freq_error(~isnan(freq_error));
            delay_error = delay_error(~isnan(delay_error));
            off_error = off_error(~isnan(off_error));
            
            % Also calculate statistics for the entire simulation (including transient)
            freq_error_all = slave_freq_log - 125e6;
            delay_error_all = (delay + drx + dtx) - ptp_delay_log;
            off_error_all = real_offset - ptp_offset_log;
            
            % Remove NaN values from full dataset
            freq_error_all = freq_error_all(~isnan(freq_error_all));
            delay_error_all = delay_error_all(~isnan(delay_error_all));
            off_error_all = off_error_all(~isnan(off_error_all));
        end
    end
end
    
% %% Plot results
% figure('Name', 'PTP Synchronization Analysis', 'Position', [100 100 1400 1200]);
% 
% % Plot 1: Clock Time Evolution
% subplot(3,1,1);
% master_time = zeros(size(times));
% slave_time = zeros(size(times));
% for idx = 1:length(times)
%     if idx <= length(slave_freq_log)
%         master_time(idx) = times(idx);  % Master is reference
%         slave_time(idx) = times(idx) + real_offset(idx);
%     end
% end
% plot(times, master_time, 'b-', 'LineWidth', 1.5);
% hold on;
% plot(times, slave_time, 'r--', 'LineWidth', 1.5);
% xlabel('Simulation Time (s)');
% ylabel('Clock Time (s)');
% title('Clock Time Evolution');
% legend('Master Clock', 'Slave Clock', 'Location', 'best');
% grid on;
% 
% % Plot 2: Real Time Offset
% subplot(3,1,2);
% plot(times, real_offset, 'r-', times, ptp_offset_log, 'g-', 'LineWidth', 1.5);
% xlabel('Time (s)');
% ylabel('Time Offset (s)');
% title('Real vs PTP Clock Offset (Slave - Master)');
% legend("Real", "PTP");
% grid on;
% 
% % Plot 3: Offset Error (Real vs PTP)
% subplot(3,1,3);
% plot(times(analysis_indices), off_error, 'r-', 'LineWidth', 1.5);
% xlabel('Time (s)');
% ylabel('Offset Error (s)');
% title('PTP Offset Error');
% grid on;

%% sim setup

%sigma = [0.00001, 0.0001, 0.001, 0.01, 0.1, 1, 10, 100, 1000, 10000, 100000] * 0.00000001;
%delay_std = (1:50:100000)*1e-11;
delay_std = linspace(1e-12, 1e-2, 1000);

off_error_mean = nan(length(delay_std));
i = 1;

%% sim loop

parfor i = 1:length(delay_std)  
    off_error = run_sim_loop(delay_std(i));
    off_error_mean(i) = abs(mean(off_error));
    fprintf("Offset error average for sigma : %.3e (after convergence) : %.3e s\n", delay_std(i), mean(off_error))
end

%% plot

figure;
plot(delay_std, off_error_mean, 'r-', 'LineWidth', 1.5);
xlabel('Delay STD (s)');
ylabel('Offset Error (s)');
title('PTP Offset Error / Delay STD');
grid on;
%xscale log;