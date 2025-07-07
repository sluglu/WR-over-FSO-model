 clear; clc;

%% PARAMETERS
f0 = 125e6;
t0 = 0;
dt = 1e-9;
N = 500;

%% INIT CLOCKS AND TIMESTAMPER

% Ideal noise profile
params_ideal = struct(...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'sigma_rw', 0, ...
    'sigma_jitter', 0 ...
);

params_meas_noise = struct(...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'sigma_rw', 0, ...
    'sigma_jitter', 5e-3 ...
);

np_ideal = noise_profile(params_ideal);

np_meas_noise = noise_profile(params_meas_noise);

ts = timestamper(np_meas_noise);

clk = master_clock(f0, t0, np_ideal);

%% BUFFERS
t_vec = (0:N-1) * dt;

phi_ideal = zeros(1, N);
phi_coarse = zeros(1, N);
phi_fine = zeros(1, N);

coarse_error = zeros(1, N);
fine_error = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    % Ideal
    phi_ideal(i) = clk.phi;

    % Coarse (Rounded)
    phi_coarse(i) = ts.getCoarsePhase(clk);
    coarse_error(i) = phi_coarse(i) -  phi_ideal(i);

    % Fine (Fractional)
    phi_fine(i) = ts.getFinePhase(clk);
    fine_error(i) = phi_fine(i) - phi_ideal(i);

    % Advance clock
    clk = clk.advance(dt);
end

%% PLOTS
figure('Name', 'Raw vs Coarse vs Fine phase measurment', 'Position', [100 100 1300 1000]);
% --- 1. Phase Evolution
subplot(2,1,1);
plot(t_vec, phi_coarse, 'r', t_vec, phi_fine, 'g', t_vec, phi_ideal, 'b--');
xlabel('Time'); ylabel('Coarse Phase (rad)');
legend('Coarse', 'Fine','Raw'); title('Phase Evolution');

% --- 2. Phase Evolution
subplot(2,1,2);
plot(t_vec, coarse_error, 'r', t_vec, fine_error, 'g', t_vec, 0*t_vec, 'b--');
xlabel('Time'); ylabel('Coarse Phase (rad)');
legend('Coarse Error', 'Fine Error', 'ideal zero error'); title('Phase Error');


%% METRICS: Phase Error and Frequency Drift
% Phase Error
mean_coarse_err = mean(coarse_error);
std_coarse_err  = std(coarse_error);

mean_fine_err = mean(fine_error);
std_fine_err  = std(fine_error);

% --- Console Output ---
fprintf('\n--- Phase Error Statistics ---\n');
fprintf('Coarse Phase Error  : Mean = %.3e rad, Std = %.3e rad\n', mean_coarse_err, std_coarse_err);
fprintf('Fine Phase Error    : Mean = %.3e rad, Std = %.3e rad\n', mean_fine_err, std_fine_err);