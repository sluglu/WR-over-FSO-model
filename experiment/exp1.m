clear; clc;

%% Parameters main sim
verbose = false;
asym_delay_std = logspace(-12, -2, 100); % Use fewer points but logarithmic spacing

function off_error = run_sim_loop(asym_delay_std, verbose)
    %% Parameters for individual sim
    sim_duration = 10;     % seconds
    dt = 0.001;            % time step
    f0 = 125e6;
    t0 = 0;
    sync_interval = 1;
    delay_a = 10e-3;
    min_msg_interval = 1e-3;
    
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
    clock_slave  = SlaveClock(f0, t0, np_noisy);
    
    %% Create nodes
    master = MasterNode(clock_master, MasterFSM(sync_interval,verbose));
    slave  = SlaveNode(clock_slave, SlaveFSM(verbose));
    
    %% Pre-allocate arrays
    max_steps = ceil(sim_duration / dt) + 1000; % Extra buffer for variable timesteps
    times = zeros(max_steps, 1);
    ptp_offset_log = nan(max_steps, 1);
    real_offset = zeros(max_steps, 1);
    
    %% Message queue
    msg_queue = cell(100, 3); % [target, msg, delivery_time] - pre-allocate
    queue_size = 0;
    queue_capacity = 100;
    
    %% Simulation loop
    sim_time = t0;
    i = 1;
    
    while sim_time < sim_duration && i <= max_steps
        times(i) = sim_time;
        
        % Step master and slave nodes
        [master, master_msgs] = master.step(sim_time);
        [slave, slave_msgs] = slave.step(sim_time, master.clock.f);
        
        % Pre-calculate delay once per iteration
        delay = delay_a + randn * asym_delay_std;
        
        % Enqueue messages from master
        for j = 1:length(master_msgs)
            queue_size = queue_size + 1;
            if queue_size > queue_capacity
                % Expand queue if needed
                queue_capacity = queue_capacity * 2;
                temp_queue = cell(queue_capacity, 3);
                temp_queue(1:queue_size-1, :) = msg_queue(1:queue_size-1, :);
                msg_queue = temp_queue;
            end
            msg_queue{queue_size, 1} = 'slave';
            msg_queue{queue_size, 2} = master_msgs{j};
            msg_queue{queue_size, 3} = sim_time + delay + min_msg_interval*j;
        end
        
        % Enqueue messages from slave
        for j = 1:length(slave_msgs)
            queue_size = queue_size + 1;
            if queue_size > queue_capacity
                % Expand queue if needed
                queue_capacity = queue_capacity * 2;
                temp_queue = cell(queue_capacity, 3);
                temp_queue(1:queue_size-1, :) = msg_queue(1:queue_size-1, :);
                msg_queue = temp_queue;
            end
            msg_queue{queue_size, 1} = 'master';
            msg_queue{queue_size, 2} = slave_msgs{j};
            msg_queue{queue_size, 3} = sim_time + delay + min_msg_interval*j;
        end
        
        % Deliver messages whose time has come
        if queue_size > 0
            % Find messages to deliver
            delivery_times = [msg_queue{1:queue_size, 3}];
            to_deliver = delivery_times <= sim_time;
            
            % Process deliveries
            for j = find(to_deliver)
                if strcmp(msg_queue{j, 1}, 'master')
                    master = master.receive(msg_queue{j, 2}, msg_queue{j, 3});
                else
                    slave = slave.receive(msg_queue{j, 2}, msg_queue{j, 3});
                end
            end
            
            % Remove delivered messages
            if any(to_deliver)
                keep_indices = find(~to_deliver);
                for k = 1:length(keep_indices)
                    msg_queue(k, :) = msg_queue(keep_indices(k), :);
                end
                queue_size = length(keep_indices);
            end
        end
        
        % Log data
        ptp_offset_log(i) = slave.fsm.last_offset;
        
        % Calculate real offset between clocks
        master_time = master.clock.phi / (2*pi*f0);
        slave_time = slave.clock.phi / (2*pi*f0);
        real_offset(i) = slave_time - master_time;
        
        % Determine next simulation time
        if queue_size > 0
            next_msg_time = min([msg_queue{1:queue_size, 3}]);
            sim_time = min(sim_time + dt, next_msg_time);
        else
            sim_time = sim_time + dt;
        end
        
        i = i + 1;
    end

    off_error = real_offset - ptp_offset_log;
    off_error = off_error(~isnan(off_error));
end

%% Main simulation setup

off_error_mean = nan(length(asym_delay_std), 1);
length_asym_delay_std = length(asym_delay_std);

% Create progress tracker object
progress = ProgressTracker(length_asym_delay_std);

% Create DataQueue and bind to tracker
dq = parallel.pool.DataQueue;
afterEach(dq, @(~) progress.update());

% Start waitbar
progress.start();

fprintf('Starting simulation with %d asymetric delay standard deviation values...\n', length(asym_delay_std));



%% Simulation loop with progress tracking
tic; % Start timing
parfor i = 1:length(asym_delay_std)
    try
        off_error = run_sim_loop(asym_delay_std(i), verbose);
        if ~isempty(off_error)
            off_error_mean(i) = abs(mean(off_error));
        end
        fprintf("Completed simulation %d/%d \n", i, length_asym_delay_std);
    catch ME
        fprintf("Error in simulation %d: %s\n", i, ME.message);
        off_error_mean(i) = NaN;
    end
    send(dq, i); 
end

% Clean up
progress.finish();

elapsed_time = toc;
fprintf('Simulation completed in %.2f seconds\n', elapsed_time);

%% Plotting
figure('Position', [100 100 1200 800]);

% Main plot
%subplot(2,1,1);
valid_indices = ~isnan(off_error_mean);
loglog(asym_delay_std(valid_indices), off_error_mean(valid_indices), 'b-', 'LineWidth', 2);
hold on;
grid on;
xlabel('Asymetric Delay Standard Deviation (s)');
ylabel('Mean Absolute Offset Error (s)');
title('PTP Offset Error vs Asymetric Delay Standard Deviation');

% Add trend line if possible
if sum(valid_indices) > 10
    % Fit a line in log space
    log_delay = log10(asym_delay_std(valid_indices));
    log_error = log10(off_error_mean(valid_indices));
    p = polyfit(log_delay, log_error, 1);
    trend_line = 10.^(polyval(p, log_delay));
    plot(asym_delay_std(valid_indices), trend_line, 'r--', 'LineWidth', 1.5);
    legend('Simulation Data', sprintf('Trend (slope = %.2f)', p(1)), 'Location', 'best');
end

% Sample index table
num_samples = 10;
sample_indices = round(linspace(1, length(asym_delay_std), num_samples));
sampled_std   = asym_delay_std(sample_indices(:));
sampled_error = off_error_mean(sample_indices(:));
sampled_log_time = log10(sampled_std(:));
T_sample = table(sample_indices(:), sampled_std(:), sampled_error(:), ...
    'VariableNames', {'Index', 'AsymDelayStd (s)', 'MeanOffsetError (s)'});

f = figure('Name', 'Sampled Offset Error Table', 'NumberTitle', 'off', ...
           'Position', [100, 100, 700, 250]);

uitable(f, ...
    'Data', T_sample{:,:}, ...
    'ColumnName', T_sample.Properties.VariableNames, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'FontSize', 12);

% Display summary statistics
fprintf('\nSummary Statistics:\n');
fprintf('Min offset error: %.3e s\n', min(off_error_mean(valid_indices)));
fprintf('Max offset error: %.3e s\n', max(off_error_mean(valid_indices)));
fprintf('Median offset error: %.3e s\n', median(off_error_mean(valid_indices)));
fprintf('Mean offset error: %.3e s\n', mean(off_error_mean(valid_indices)));

%% Save results
save('exp1_PTP_offset_error_vs_asym_delay_STD.mat', 'asym_delay_std', 'off_error_mean', 'elapsed_time');
fprintf('Results saved to exp1_PTP_offset_error_vs_asym_delay_STD.mat\n');