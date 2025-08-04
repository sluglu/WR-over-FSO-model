clear; clc; close all;

%% Simulation Parameters
dt_orbital = 1;            % Orbital position update interval [s]
sim_duration = 1;          % Total simulation duration [hours]
dt_ptp = 0.001;            % PTP simulation time step [s]
sync_interval = 0.5;         % PTP sync interval [s]
min_los_duration = 1;      % Minimum LOS duration to simulate PTP [s]
verbose = false;
min_msg_interval = 1e-3;

%% Constants
deg = pi/180;
rE = 6371e3;               % Earth radius [m]
c = 299792458;             % Speed of light [m/s]
f0 = 125e6;                % Reference frequency [Hz]

%% Orbital Scenario Selection
scenarios = {
    "StarLink V1 like",                     rE+550e3, rE+550e3, 53*deg,  53*deg,     0,         0,       0,       70*deg;
    "Opposite Inclination",                 rE+550e3, rE+550e3, 45*deg, -45*deg,     0,         0,       0,       0;
    "Walker Delta (shared plane)",          rE+1200e3,rE+1200e3,55*deg,  55*deg,     0,         0,       0,      36*deg;
    "Polar Orbit (counter-rotating)",       rE+800e3, rE+800e3, 90*deg, -90*deg,     0,         0,       0,       0;
};

scenario_idx = 1; % Select scenario to simulate
fprintf('Simulating scenario: %s\n', scenarios{scenario_idx,1});


%% Continuous PTP Simulation for Entire Duration
function [results] = simulate_ptp_continuous(sim_duration, ptp_params, scenario)

    % Extract parameters
    dt_ptp = ptp_params.dt_ptp;
    dt_orbital = ptp_params.dt_orbital;
    f0 = ptp_params.f0;
    sync_interval = ptp_params.sync_interval;
    verbose = ptp_params.verbose;
    min_msg_interval = ptp_params.min_msg_interval;
    min_los_duration = ptp_params.min_los_duration;

    % Unpack Selected Scenario
    r1_val = scenario(2); r2_val = scenario(3);
    i1 = scenario(4);     i2 = scenario(5);
    th1 = scenario(6);    th2 = scenario(7);
    omega1 = scenario(8); omega2 = scenario(9);
    
    params1 = struct('r', r1_val, 'i', i1, 'theta0', th1, 'RAAN', omega1);
    params2 = struct('r', r2_val, 'i', i2, 'theta0', th2, 'RAAN', omega2);
    
    % Generate Orbital Functions and LOS Data
    [r1, r2] = generate_position_functions(params1, params2);
    tspan = 0:dt_orbital:sim_duration*3600;
    [los_intervals, los_flags] = compute_los_intervals(r1, r2, tspan);
    
    % Filter LOS intervals by minimum duration
    valid_intervals = [];
    for i = 1:size(los_intervals,1)
        duration = los_intervals(i,2) - los_intervals(i,1);
        if duration >= min_los_duration
            valid_intervals = [valid_intervals; los_intervals(i,:)];
        end
    end
    
    if isempty(valid_intervals)
        error('No LOS intervals meet minimum duration requirement of %.1f seconds', min_los_duration);
    end
    
    fprintf('Found %d valid LOS intervals (>= %.1f s duration)\n', size(valid_intervals,1), min_los_duration);

    
    
    % Initialize PTP components
    np_ideal = NoiseProfile(struct('delta_f0', 0, 'alpha', 0, 'sigma_rw', 0, 'sigma_jitter', 0));
    
    clock_master = MasterClock(f0, 0, np_ideal);
    clock_slave = SlaveClock(f0, 0, np_ideal);
    
    master = MasterNode(clock_master, MasterFSM(sync_interval, verbose));
    slave = SlaveNode(clock_slave, SlaveFSM(verbose));
    
    % Pre-allocate arrays for entire simulation
    total_duration = sim_duration * 3600;
    max_steps = ceil(total_duration / dt_ptp) + 1000;
    
    times = zeros(max_steps, 1);
    ptp_offset_log = nan(max_steps, 1);
    ptp_delay_log = nan(max_steps, 1);
    real_offset = zeros(max_steps, 1);
    propagation_delays = zeros(max_steps, 1);
    los_status = zeros(max_steps, 1);
    
    % Message queue
    msg_queue = cell(100, 3);
    queue_size = 0;
    queue_capacity = 100;
    
    % Progress tracking
    total_los_duration = sum(valid_intervals(:,2) - valid_intervals(:,1));
    current_interval = 1;
    processed_los_duration = 0;
    
    % Simulation loop
    sim_time = 0;
    i = 1;
    
    fprintf('Starting continuous PTP simulation...\n');
    tic;
    
    while sim_time < total_duration && i <= max_steps
        times(i) = sim_time;
        
        % Determine LOS status
        los_idx = find(tspan <= sim_time, 1, 'last');
        if isempty(los_idx), los_idx = 1; end
        if los_idx > length(los_flags), los_idx = length(los_flags); end
        los_status(i) = los_flags(los_idx);
        
        % Calculate propagation delay
        if los_status(i)
            [propagation_delays(i), ~, ~, ~] = compute_propagation_delay(r1, r2, sim_time);
        else
            propagation_delays(i) = NaN;
        end
        
        % Calculate real clock offset
        master_time = master.clock.phi / (2*pi*f0);
        slave_time = slave.clock.phi / (2*pi*f0);
        real_offset(i) = slave_time - master_time;
        
        if los_status(i)
            % PTP operation during LOS
            [master, master_msgs] = master.step(sim_time);
            [slave, slave_msgs] = slave.step(sim_time, master.clock.f);
            
            % Enqueue messages with propagation delay
            for j = 1:length(master_msgs)
                queue_size = queue_size + 1;
                if queue_size > queue_capacity
                    queue_capacity = queue_capacity * 2;
                    temp_queue = cell(queue_capacity, 3);
                    temp_queue(1:queue_size-1, :) = msg_queue(1:queue_size-1, :);
                    msg_queue = temp_queue;
                end
                msg_queue{queue_size, 1} = 'slave';
                msg_queue{queue_size, 2} = master_msgs{j};
                msg_queue{queue_size, 3} = sim_time + propagation_delays(i) + j*min_msg_interval;
            end
            
            for j = 1:length(slave_msgs)
                queue_size = queue_size + 1;
                if queue_size > queue_capacity
                    queue_capacity = queue_capacity * 2;
                    temp_queue = cell(queue_capacity, 3);
                    temp_queue(1:queue_size-1, :) = msg_queue(1:queue_size-1, :);
                    msg_queue = temp_queue;
                end
                msg_queue{queue_size, 1} = 'master';
                msg_queue{queue_size, 2} = slave_msgs{j};
                msg_queue{queue_size, 3} = sim_time + propagation_delays(i);
            end
            
            % Deliver messages
            if queue_size > 0
                delivery_times = [msg_queue{1:queue_size, 3}];
                to_deliver = delivery_times <= sim_time;
                
                for j = find(to_deliver)
                    if strcmp(msg_queue{j, 1}, 'master')
                        master = master.receive(msg_queue{j, 2}, msg_queue{j, 3});
                    else
                        slave = slave.receive(msg_queue{j, 2}, msg_queue{j, 3});
                    end
                end
                
                if any(to_deliver)
                    keep_indices = find(~to_deliver);
                    for k = 1:length(keep_indices)
                        msg_queue(k, :) = msg_queue(keep_indices(k), :);
                    end
                    queue_size = length(keep_indices);
                end
            end
            
            % Log PTP offset and delay
            ptp_offset_log(i) = slave.fsm.last_offset;
            ptp_delay_log(i) = slave.fsm.last_delay;

            % Determine next simulation time
            if queue_size > 0
                next_msg_time = min([msg_queue{1:queue_size, 3}]);
                sim_time = min(sim_time + dt_ptp, next_msg_time);
            else
                sim_time = sim_time + dt_ptp;
            end
            
            % Progress tracking
            if current_interval <= size(valid_intervals, 1)
                if sim_time >= valid_intervals(current_interval, 1) && sim_time <= valid_intervals(current_interval, 2)
                    interval_duration = valid_intervals(current_interval, 2) - valid_intervals(current_interval, 1);
                    interval_progress = min(sim_time - valid_intervals(current_interval, 1), interval_duration);
                    progress_percent = 100 * (processed_los_duration + interval_progress) / total_los_duration;
                    
                    if mod(i, 10000) == 0
                        fprintf('  Progress: %.1f%% (Interval %d/%d, %.1f min)\n', ...
                            progress_percent, current_interval, size(valid_intervals, 1), sim_time/60);
                    end
                elseif sim_time > valid_intervals(current_interval, 2)
                    processed_los_duration = processed_los_duration + ...
                        (valid_intervals(current_interval, 2) - valid_intervals(current_interval, 1));
                    current_interval = current_interval + 1;
                end
            end
        else
            % No LOS - advance with orbital time step
            master = master.advance_time(dt_orbital);
            slave = slave.advance_time(dt_orbital);
            queue_size = 0;
            ptp_offset_log(i) = NaN;
            ptp_delay_log(i) = NaN;
            sim_time = sim_time + dt_orbital;
            
            if mod(i, 1000) == 0
                fprintf('  No-LOS period: %.1f min\n', sim_time/60);
            end
        end
        
        i = i + 1;
    end
    
    elapsed_time = toc;
    fprintf('Continuous simulation completed in %.2f seconds\n', elapsed_time);
    
    % Prepare results
    valid_idx = i-1;
    results = struct();
    results.times = times(1:valid_idx);
    results.ptp_offset = ptp_offset_log(1:valid_idx);
    results.ptp_delay = ptp_delay_log(1:valid_idx);
    results.real_offset = real_offset(1:valid_idx);
    results.propagation_delays = propagation_delays(1:valid_idx);
    results.los_status = los_status(1:valid_idx);
    results.los_flags = los_flags;
    results.total_duration = total_duration;
    results.tspan = tspan;
    results.r1 = r1;
    results.r2 = r2;
    results.los_intervals = valid_intervals;
end

%% Run Simulation
ptp_params = struct('dt_ptp', dt_ptp, 'dt_orbital', dt_orbital, 'f0', f0, ...
                   'sync_interval', sync_interval, 'min_msg_interval', ...
                   min_msg_interval, 'verbose', verbose, 'min_los_duration', min_los_duration);

results = simulate_ptp_continuous(sim_duration, ptp_params, scenarios(scenario_idx, :));

%% Generate orbital positions for plotting
pos1 = zeros(3, length(results.tspan));
pos2 = zeros(3, length(results.tspan));
for k = 1:length(results.tspan)
    pos1(:,k) = results.r1(results.tspan(k));
    pos2(:,k) = results.r2(results.tspan(k));
end

%% Plotting
figure('Position', [100, 100, 1400, 800]);

% Plot 1: 3D Orbital trajectories with LOS links
subplot(2,3,1);
hold on;
plot3(pos1(1,:), pos1(2,:), pos1(3,:), '-', 'Color', [1 0 0], 'LineWidth', 1.2, 'DisplayName', 'Satellite 1');
plot3(pos2(1,:), pos2(2,:), pos2(3,:), '-', 'Color', [0 0 1], 'LineWidth', 1.2, 'DisplayName', 'Satellite 2');

% Earth sphere
[xe, ye, ze] = sphere(50);
surf(xe*rE, ye*rE, ze*rE, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', [0.6 0.6 1], 'DisplayName', 'Earth');

% LOS connection lines
for intv = 1:size(results.los_intervals,1)
    idxs = find(results.tspan >= results.los_intervals(intv,1) & results.tspan <= results.los_intervals(intv,2));
    for k = idxs(1:5:end)
        if k <= size(pos1,2)
            plot3([pos1(1,k), pos2(1,k)], [pos1(2,k), pos2(2,k)], [pos1(3,k), pos2(3,k)], ...
                  'g-', 'LineWidth', 0.5);
        end
    end
end

axis equal; grid on;
xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
title('3D Orbital Trajectories with LOS');
hold off;

% Plot 2: LOS intervals overview
subplot(2,3,2);
area(results.tspan/60, results.los_flags, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.5, 'DisplayName', 'LOS Available');
hold on;
for i = 1:size(results.los_intervals,1)
    plot([results.los_intervals(i,1)/60, results.los_intervals(i,2)/60], [1.1, 1.1], 'r-', 'LineWidth', 3);
end
ylim([0, 1.2]);
xlabel('Time [min]'); ylabel('LOS Status');
title('LOS Intervals');
legend('LOS Available', 'PTP Simulated', 'Location', 'best');
grid on;
hold off;

% Plot 3: Propagation delays and PTP delay estimates
subplot(2,3,3);
plot(results.times/60, results.propagation_delays, 'r', 'DisplayName', 'True Propagation Delay');
hold on;
plot(results.times/60, results.ptp_delay, 'b', 'DisplayName', 'PTP Delay Estimate');
xlabel('Time [min]');
xlim([0 sim_duration*60]);
ylabel('Delay [s]');
title('Propagation Delays and PTP Delays Estimate');
legend('show', 'Location', 'best');
grid on;

% Plot 4-6: Clock synchronization performance
subplot(2,3,[4,6]);
hold on;
% LOS background area (no plot data, just visual)
area(results.tspan/60, results.los_flags, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', 'LOS Intervals');

% Clock offset plots
plot(results.times/60, results.real_offset, 'r-', 'LineWidth', 1.5, 'DisplayName', 'True Offset');

ptp_valid = ~isnan(results.ptp_offset);
plot(results.times(ptp_valid)/60, results.ptp_offset(ptp_valid), 'b-', 'LineWidth', 1.5, 'DisplayName', 'PTP Estimate');

ylabel('Clock Offset [s]');
xlabel('Time [min]');
title('Clock Synchronization Performance Over Time');
legend('show', 'Location', 'best');
grid on;
hold off;


name = scenarios{scenario_idx, 1};
sgtitle(sprintf('PTP Orbital Simulation Results - %s', name), 'FontSize', 14, 'FontWeight', 'bold');

%% Save Results
save_filename = sprintf('exp2_PTP_orbital_sim_%s.mat', strrep(name, ' ', '_'));
save(save_filename, 'results');
fprintf('\nResults saved to %s\n', save_filename);