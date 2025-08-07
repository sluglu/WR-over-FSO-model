clear; clc;

%% Parameters
sim_duration = 10;     % seconds
dt = 0.001;            % time step
f0 = 125e6;
t0 = 0;
sync_interval = 1;
delay = 10e-3;
dtx = 2e-3;
drx = 1e-3;

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
clock_slave  = SlaveClock(f0, t0 + 10, np_noisy);  % 10s initial offset

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
    [slave, slave_msgs] = slave.step(sim_time);

    % Check if slave just completed a sync
    if slave.just_synced()
        sync_event_times(end+1) = sim_time;
    end

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
    slave_freq_log(i) = slave.get_freq();
    [ptp_offset_log(i), ptp_delay_log(i)] = slave.get_ptp_estimate();
    
    % Calculate real offset between clocks
    master_time = master.get_time();
    slave_time = slave.get_time();
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
convergence_threshold = 1e-9;

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
    
    %% Plot results
    figure('Name', 'PTP Synchronization Analysis', 'Position', [0 0 1000 800]);
    
    % Plot 1: Clock Time Evolution
    subplot(3,3,1);
    master_time = zeros(size(times));
    slave_time = zeros(size(times));
    for idx = 1:length(times)
        if idx <= length(slave_freq_log)
            master_time(idx) = times(idx);  % Master is reference
            slave_time(idx) = times(idx) + real_offset(idx);
        end
    end
    plot(times, master_time, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(times, slave_time, 'r--', 'LineWidth', 1.5);
    xlabel('Simulation Time (s)');
    ylabel('Clock Time (s)');
    title('Clock Time Evolution');
    legend('Master Clock', 'Slave Clock', 'Location', 'best');
    grid on;
    
    % Plot 2: Real Time Offset
    subplot(3,3,2);
    plot(times, real_offset, 'r-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Time Offset (s)');
    title('Real Clock Offset (Slave - Master)');
    grid on;
    
    % Plot 3: PTP Measured Offset
    subplot(3,3,3);
    plot(times, ptp_offset_log, 'g-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('PTP Offset (s)');
    title('PTP Measured Offset');
    grid on;
    
    % Plot 4: Frequency Error
    subplot(3,3,4);
    plot(times, slave_freq_log - 125e6, 'b-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Frequency Error (Hz)');
    title('Frequency Error');
    grid on;
    
    % Plot 5: PTP Delay Measurement
    subplot(3,3,5);
    plot(times, ptp_delay_log * 1e3, 'c-', 'LineWidth', 1.5);
    hold on;
    plot(times, (delay + drx + dtx) * 1e3 * ones(size(times)), 'k--', 'LineWidth', 1);
    xlabel('Time (s)');
    ylabel('Delays (s)');
    title('PTP Delay Measurement');
    legend('Measured', 'Expected', 'Location', 'best');
    grid on;
    
    % Plot 6: Offset Error (Real vs PTP)
    subplot(3,3,6);
    offset_error = real_offset - ptp_offset_log;
    plot(times, offset_error, 'r-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Offset Error (s)');
    title('PTP Offset Error');
    grid on;
    
    % Plot 7: Convergence Analysis
    subplot(3,3,7);
    convergence_window = 100;  % samples
    if length(real_offset) > convergence_window
        conv_times = times(convergence_window:end);
        conv_offset = real_offset(convergence_window:end);
        abs_offset = abs(conv_offset);
        
        % Calculate moving RMS
        rms_window = 50;
        rms_offset = zeros(size(conv_offset));
        for idx = rms_window:length(conv_offset)
            rms_offset(idx) = sqrt(mean(conv_offset(idx-rms_window+1:idx).^2));
        end
        
        semilogy(conv_times, abs_offset, 'b-', 'LineWidth', 1);
        hold on;
        semilogy(conv_times, rms_offset, 'r-', 'LineWidth', 2);
        xlabel('Time (s)');
        ylabel('Offset Magnitude (s)');
        title('Convergence Analysis');
        legend('Absolute Offset', 'RMS Offset', 'Location', 'best');
        grid on;
    end
    
    % Plot 8: Sync Events Timeline
    subplot(3,3,8);
    if ~isempty(sync_event_times)
        % Get the offset values at sync event times
        sync_offsets = [];
        for sync_time = sync_event_times
            [~, closest_idx] = min(abs(times - sync_time));
            sync_offsets(end+1) = ptp_offset_log(closest_idx);
        end
        
        stem(sync_event_times, sync_offsets, 'g-', 'LineWidth', 2, 'MarkerSize', 8);
        xlabel('Time (s)');
        ylabel('Sync Offset (s)');
        title('PTP Sync Events');
        grid on;
        
        % Add text annotations for sync events
        for i = 1:length(sync_event_times)
            text(sync_event_times(i), sync_offsets(i), ...
                sprintf('  #%d', i), 'VerticalAlignment', 'bottom');
        end
    end
    
    % Plot 9: Error Statistics Over Time
    subplot(3,3,9);
    window_size = 500;  % samples for moving statistics
    if length(offset_error) > window_size
        moving_mean = zeros(size(offset_error));
        moving_std = zeros(size(offset_error));
        
        for idx = window_size:length(offset_error)
            window_data = offset_error(idx-window_size+1:idx);
            window_data = window_data(~isnan(window_data));
            if ~isempty(window_data)
                moving_mean(idx) = mean(window_data);
                moving_std(idx) = std(window_data);
            end
        end
        
        plot(times, moving_mean, 'b-', 'LineWidth', 1.5);
        hold on;
        plot(times, moving_std, 'r-', 'LineWidth', 1.5);
        xlabel('Time (s)');
        ylabel('Offset Error (s)');
        title('Moving Statistics');
        legend('Mean', 'Std Dev', 'Location', 'best');
        grid on;
    end
    
    %% Additional Metrics
    
    % Basic error statistics
    mean_freq_err = mean(freq_error);
    std_freq_err  = std(freq_error);
    
    mean_delay_err = mean(delay_error);
    std_delay_err  = std(delay_error);
    
    mean_off_err = mean(off_error);
    std_off_err  = std(off_error);
    
    % Advanced metrics
    max_offset_err = max(abs(off_error));
    rms_offset_err = sqrt(mean(off_error.^2));
    
    % Convergence metrics
    if length(real_offset) > 1000
        final_1000 = real_offset(end-999:end);
        final_1000 = final_1000(~isnan(final_1000));
        if ~isempty(final_1000)
            steady_state_mean = mean(final_1000);
            steady_state_std = std(final_1000);
            steady_state_max = max(abs(final_1000));
        else
            steady_state_mean = NaN;
            steady_state_std = NaN;
            steady_state_max = NaN;
        end
    else
        steady_state_mean = NaN;
        steady_state_std = NaN;
        steady_state_max = NaN;
    end
    
    % Time to convergence
    converged_idx = find(abs(real_offset) < convergence_threshold, 1);
    if ~isempty(converged_idx)
        time_to_converge = times(converged_idx);
    else
        time_to_converge = NaN;
    end
    
    % Sync success rate - use the tracked sync events
    total_expected_syncs = floor(sim_duration / sync_interval);
    actual_syncs = length(sync_event_times);
    sync_success_rate = (actual_syncs / total_expected_syncs) * 100;
    
    % Delay measurement accuracy
    expected_delay = delay + drx + dtx;
    delay_measurements = ptp_delay_log(~isnan(ptp_delay_log));
    if ~isempty(delay_measurements)
        delay_accuracy = mean(abs(delay_measurements - expected_delay));
        delay_precision = std(delay_measurements);
    else
        delay_accuracy = NaN;
        delay_precision = NaN;
    end
    
    fprintf('\n=== PTP SYNCHRONIZATION PERFORMANCE ANALYSIS ===\n');
    fprintf('\n--- Basic Error Statistics (after convergence) ---\n');
    fprintf('Frequency Error    : Mean = %.3e Hz, Std = %.3e Hz\n', mean_freq_err, std_freq_err);
    fprintf('Delay Error        : Mean = %.3e s, Std = %.3e s\n', mean_delay_err, std_delay_err);
    fprintf('Offset Error       : Mean = %.3e s, Std = %.3e s\n', mean_off_err, std_off_err);
    fprintf('Max Offset Error   : %.3e s\n', max_offset_err);
    fprintf('RMS Offset Error   : %.3e s\n', rms_offset_err);
    
    fprintf('\n--- Full Simulation Statistics (including transient) ---\n');
    fprintf('Frequency Error    : Mean = %.3e Hz, Std = %.3e Hz\n', mean(freq_error_all), std(freq_error_all));
    fprintf('Delay Error        : Mean = %.3e s, Std = %.3e s\n', mean(delay_error_all), std(delay_error_all));
    fprintf('Offset Error       : Mean = %.3e s, Std = %.3e s\n', mean(off_error_all), std(off_error_all));
    fprintf('Max Offset Error   : %.3e s\n', max(abs(off_error_all)));
    fprintf('RMS Offset Error   : %.3e s\n', sqrt(mean(off_error_all.^2)));
    
    fprintf('\n--- Convergence Performance ---\n');
    if ~isnan(time_to_converge)
        fprintf('Time to Converge   : %.3f s (< %.2e threshold)\n', time_to_converge, convergence_threshold);
    else
        fprintf('Time to Converge   : Did not converge within simulation\n');
    end
    
    if ~isnan(steady_state_mean)
        fprintf('Steady State Mean  : %.3e s (%.1f μs)\n', steady_state_mean, steady_state_mean);
        fprintf('Steady State Std   : %.3e s (%.1f μs)\n', steady_state_std, steady_state_std);
        fprintf('Steady State Max   : %.3e s (%.1f μs)\n', steady_state_max, steady_state_max);
    end
    
    fprintf('\n--- Synchronization Quality ---\n');
    fprintf('Expected Syncs     : %d\n', total_expected_syncs);
    fprintf('Actual Syncs       : %d\n', actual_syncs);
    fprintf('Sync Success Rate  : %.1f%%\n', sync_success_rate);
    if ~isempty(sync_event_times)
        fprintf('Sync Event Times   : [');
        for i = 1:length(sync_event_times)
            fprintf('%.3f', sync_event_times(i));
            if i < length(sync_event_times), fprintf(', '); end
        end
        fprintf(']\n');
    end
    
    fprintf('\n--- Delay Measurement Performance ---\n');
    fprintf('Expected Delay     : %.3e s (%.1f ms)\n', expected_delay, expected_delay * 1e3);
    if ~isnan(delay_accuracy)
        fprintf('Delay Accuracy     : %.3e s (%.1f μs)\n', delay_accuracy, delay_accuracy);
        fprintf('Delay Precision    : %.3e s (%.1f μs)\n', delay_precision, delay_precision);
    end
    
    fprintf('\n--- System Parameters ---\n');
    fprintf('Sync Interval      : %.3f s\n', sync_interval);
    fprintf('Network Delay      : %.3f ms\n', delay * 1e3);
    fprintf('TX Delay           : %.3f ms\n', dtx * 1e3);
    fprintf('RX Delay           : %.3f ms\n', drx * 1e3);
    fprintf('Total Path Delay   : %.3f ms\n', (delay + dtx + drx) * 1e3);
    
    fprintf('\n--- Analysis Parameters ---\n');
    fprintf('Simulation Duration: %.1f s\n', sim_duration);
    fprintf('Convergence Index  : %d (%.3f s)\n', convergence_idx, times(convergence_idx));
    fprintf('Analysis Start     : %d (%.3f s)\n', analysis_start, times(analysis_start));
    fprintf('Samples Analyzed   : %d/%d (%.1f%%)\n', length(analysis_indices), length(times), ...
            length(analysis_indices)/length(times)*100);
    
    fprintf('\n=== END ANALYSIS ===\n');
else
    fprintf('No sync achieved during simulation\n');
end