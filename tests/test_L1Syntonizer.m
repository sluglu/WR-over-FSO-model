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
    'sigma_rw', 50, ...
    'sigma_jitter', 100 ...
);
np_master = NoiseProfile(params_master);
clk_master = MasterClock(f0, t0, np_master);

params_slave = struct(...
    'delta_f0', 1000, ...
    'alpha', 5, ...
    'sigma_rw', 1000, ...
    'sigma_jitter', 5000 ...
);
np_slave = NoiseProfile(params_slave);
clk_slave = SlaveClock(f0, t0, np_slave);

synt = L1Syntonizer(np_master);

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
    phi_master(i) = clk_master.phi;
    phi_slave(i) = clk_slave.phi;
    phi_error(i) = clk_slave.phi - clk_master.phi;

    % frequency
    f_master(i) = clk_master.f;
    f_slave(i) = clk_slave.f;
    f_error(i) = clk_slave.f - clk_master.f;

    % syntonization
    if i > N/2
        clk_slave = synt.syntonize(clk_master.f, clk_slave);
    end

    % Advance clocks
    clk_master = clk_master.advance(dt);
    clk_slave = clk_slave.advance(dt);
end

%% PLOTS

center_value = t_vec(N/2);

figure('Name', 'L1 Syntonizer Test', 'Position', [100 100 1300 1000]);

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