clear; clc;

%% PARAMETERS
f0 = 125e6;
sync_interval = 1;
sim_duration = 10;
dt = 0.001;
delay = 5e-3;
initial_offset = 1.0;  % Initial time offset [s]
t0 = 0;

%% INITIALIZE CLOCKS WITH OFFSET
params_noisy = struct( ...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'power_law_coeffs', [8e-24, 1e-27, 1e-28, 4e-32, 2e-34], ...  % Typical OCXO values
    'timestamp_resolution', 1 ...
    );
np = NoiseProfile(params_noisy);

clock_master = MasterClock(f0, t0, NoiseProfile());
clock_slave = SlaveClock(f0, t0 + initial_offset, np);  % Start with offset

master = MasterNode(clock_master, MasterFSM(sync_interval, false));
slave = SlaveNode(clock_slave, SlaveFSM(false));

%% SIMULATION VARIABLES
msg_queue = {};
times = [];
real_offset = [];
corrections_applied = [];
correction_times = [];

%% SIMULATION LOOP
sim_time = t0;
i = 1;

fprintf('Testing offset correction with initial offset: %.3f s\n', initial_offset);

disp(slave.get_time() - master.get_time())

while sim_time < sim_duration
    times(i) = sim_time;
    actual_dt = times(max(i,1)) - times(max(i-1,1));
    
    % Step nodes
    [master, master_msgs] = master.step(actual_dt);
    [slave, slave_msgs] = slave.step(actual_dt);
    
    % Handle messages (simplified)
    for j = 1:length(master_msgs)
        msg_queue{end+1,1} = 'slave';
        msg_queue{end,2} = master_msgs{j};
        msg_queue{end,3} = sim_time + delay;
    end
    for j = 1:length(slave_msgs)
        msg_queue{end+1,1} = 'master';
        msg_queue{end,2} = slave_msgs{j};
        msg_queue{end,3} = sim_time + delay;
    end
    
    % Deliver messages
    if ~isempty(msg_queue)
        delivery_times = [msg_queue{:,3}];
        to_deliver = delivery_times <= sim_time;
        for j = find(to_deliver)
            if strcmp(msg_queue{j,1}, 'master')
                master = master.receive(msg_queue{j,2});
            else
                slave = slave.receive(msg_queue{j,2});
            end
        end
        msg_queue(to_deliver,:) = [];
    end
    
    % Check if sync completed and apply correction
    if slave.just_synced()
        [ptp_offset, ~] = slave.get_ptp_estimate();
        slave = slave.offset_correction();
        
        corrections_applied(end+1) = ptp_offset;
        correction_times(end+1) = sim_time;
        fprintf('Correction applied at t=%.3f s: %.6f s\n', sim_time, ptp_offset);
    end
    
    % Log real offset
    master_time = master.get_time();
    slave_time = slave.get_time();
    real_offset(i) = slave_time - master_time;
    
    sim_time = sim_time + dt;
    i = i + 1;
end

%% RESULTS
fprintf('\n=== RESULTS ===\n');
fprintf('Initial offset: %.6f s\n', initial_offset);
fprintf('Final offset: %.6f s\n', real_offset(end));
fprintf('Number of corrections: %d\n', length(corrections_applied));
fprintf('Improvement factor: %.1fx\n', abs(initial_offset / real_offset(end)));

%% SIMPLE PLOTS
figure('Position', [100, 100, 1200, 400]);

% Plot 1: Real offset over time
subplot(1,3,1);
plot(times, real_offset, 'b-', 'LineWidth', 2);
hold on;
for k = 1:length(correction_times)
    xline(correction_times(k), 'r--', sprintf('Corr %.3fs', corrections_applied(k)));
end
xlabel('Time [s]');
ylabel('Real Offset [s]');
title('Clock Offset vs Time');
grid on;

% Plot 2: Corrections applied
subplot(1,3,2);
if ~isempty(correction_times)
    stem(correction_times, corrections_applied, 'r', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('Time [s]');
    ylabel('Correction [s]');
    title('Offset Corrections');
    grid on;
end

% Plot 3: Convergence (log scale)
subplot(1,3,3);
semilogy(times, abs(real_offset), 'b-', 'LineWidth', 2);
xlabel('Time [s]');
ylabel('|Offset| [s]');
title('Convergence (Log Scale)');
grid on;