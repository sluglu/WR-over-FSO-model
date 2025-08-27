clear; clc;

%% PARAMETERS
f0 = 125e6;
t0 = 0;
dt = 1e-6;
N = 5000;

%% INIT CLOCKS AND L1_syntonizer
params_master = struct(...
     'delta_f0', 0, ...
    'alpha', 1, ...
    'power_law_coeffs', [1e-25, 5e-24, 1e-22, 2e-20, 5e-21] ...  % Typical OCXO values
);
np_master = NoiseProfile(params_master);
master_clock = MasterClock(f0, t0, np_master);
master = MasterNode(master_clock, MasterFSM());

params_slave = struct(...
    'delta_f0', 10, ...
    'alpha', 5e-10, ...
    'power_law_coeffs', [1e-25, 5e-24, 1e-22, 2e-20, 5e-21] ...  % Typical OCXO values
);
np_slave = NoiseProfile(params_slave);
slave_clock = SlaveClock(f0, t0, np_slave);
slave = SlaveNode(slave_clock, SlaveFSM());

%% BUFFERS
t_vec = (0:N-1) * dt + t0;

phi_master = zeros(1, N);
phi_slave = zeros(1, N);

f_master = zeros(1, N);
f_slave = zeros(1, N);

phi_error = zeros(1, N);
f_error = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    % phase
    phi_master(i) = master.get_phi();
    phi_slave(i) = slave.get_phi();
    phi_error(i) = slave.get_phi() - master.get_phi();

    % frequency
    f_master(i) = master.get_freq();
    f_slave(i) = slave.get_freq();
    f_error(i) = slave.get_freq() - master.get_freq();

    % syntonization
    if i > N/2
        slave = slave.syntonize(master.get_freq());
    end

    % Advance clocks
    master = master.advance_time(dt);
    slave = slave.advance_time(dt);
end

%% PLOTS

center_value = t_vec(N/2);

figure('Name', 'L1 Syntonizer Test', 'Position', [100 -100 1300 1000]);

% --- 1. Frequency
subplot(3,1,1);
plot(t_vec, f_master, 'r', t_vec, f_slave, 'g');
xlabel('Time'); ylabel('frequency (Hz)');
title('Frequency');
xline(center_value, 'b--', 'L1 Syntonizer ON');
legend('Master', 'Slave');

% --- 2. Phase Error 
subplot(3,1,2);
plot(t_vec, phi_error, 'r');
xlabel('Time'); ylabel('Phase Error (rad)');
title('Phase Error');
xline(center_value, 'b--', 'L1 Syntonizer ON');

% --- 3. Frequency Error 
subplot(3,1,3);
plot(t_vec, f_error, 'r');
xlabel('Time'); ylabel('Frequency Error (Hz)');
title('Frequency Error');
xline(center_value, 'b--', 'L1 Syntonizer ON');


%% METRICS: Phase Error and Frequency Drift
% Phase Error
mean_f_err = mean(f_error);
std_f_err  = std(f_error);

mean_phi_err = mean(phi_error);
std_phi_err  = std(phi_error);

% --- Console Output ---
fprintf('\n--- Phase and Frequency Error Statistics ---\n');
fprintf('Phase Error  : Mean = %.3e rad, Std = %.3e rad\n', mean_phi_err, std_phi_err);
fprintf('Frequency Error    : Mean = %.3e Hz, Std = %.3e Hz\n', mean_f_err, std_f_err);