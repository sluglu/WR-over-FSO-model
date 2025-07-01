% test_clock_phase_components.m
% Full diagnostic comparison of ideal vs noisy clock

clear; clc;

%% PARAMETERS
f0 = 125e6;
phi0 = 0;
dt = 1e-12;
N = 5000;

% Noisy profile
params_noisy = struct(...
    'delta_f0', 1e3, ...
    'alpha', 100, ...
    'sigma_rw', 500, ...
    'sigma_jitter', 100 ...
);

% Ideal profile
params_ideal = struct(...
    'delta_f0', 0, ...
    'alpha', 0, ...
    'sigma_rw', 0, ...
    'sigma_jitter', 0 ...
);

%% INIT CLOCKS
np_noisy = noise_profile(params_noisy);
np_ideal = noise_profile(params_ideal);

clk_noisy = master_clock(f0, phi0, np_noisy);
clk_ideal = master_clock(f0, phi0, np_ideal);

%% BUFFERS
t_vec = (0:N-1) * dt;

phi_noisy = zeros(1, N);
phi_ideal = zeros(1, N);
phi_error = zeros(1, N);

coarse_noisy = zeros(1, N);
coarse_error = zeros(1, N);

fine_noisy = zeros(1, N);
fine_error = zeros(1, N);

eta_vec = zeros(1, N);
df_vec = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    % Ideal
    phi_ideal(i) = clk_ideal.phi;

    % Coarse (Rounded)
    coarse_noisy(i) = clk_noisy.getCoarsePhase();
    coarse_error(i) = coarse_noisy(i) -  phi_ideal(i);

    % Fine (Fractional)
    fine_noisy(i) = clk_noisy.getFinePhase();
    fine_error(i) = fine_noisy(i) - phi_ideal(i);

    % Noise state
    eta_vec(i) = clk_noisy.noise_profile.eta;

    % Save current total freq deviation (est.)
    df_vec(i) = params_noisy.delta_f0 + ...
                params_noisy.alpha * clk_noisy.noise_profile.t_accum + ...
                clk_noisy.noise_profile.eta;

    % Advance clocks
    clk_noisy = clk_noisy.advance(dt);
    clk_ideal = clk_ideal.advance(dt);
end

%% PLOTS
figure('Name', 'Clock Phase Component Breakdown', 'Position', [100 100 1300 1000]);
% --- 1. Coarse Phase
subplot(3,2,1);
plot(t_vec*1e6, phi_ideal, 'b--', t_vec*1e6, coarse_noisy, 'r');
xlabel('Time (µs)'); ylabel('Coarse Phase (rad)');
legend('Ideal','Noisy'); title('Coarse Evolution (Rounded)');

% --- 2. Fine Phase
subplot(3,2,2);
plot(t_vec*1e6, phi_ideal, 'b--', t_vec*1e6, fine_noisy, 'r');
xlabel('Time (µs)'); ylabel('Fine Phase (rad)');
legend('Ideal','Noisy'); title('Fine Phase Evolution (Fractional)');

% --- 3. Phase Error Comparison
subplot(3,2,3);
plot(t_vec*1e6, coarse_error, 'g--', ...
     t_vec*1e6, fine_error, 'm:');
xlabel('Time (µs)'); ylabel('Error (rad)');
legend('Coarse','Fine'); title('Phase Error Comparison');

% --- 4. Random Walk η(t)
subplot(3,2,4);
plot(t_vec*1e6, eta_vec, 'b');
xlabel('Time (µs)'); ylabel('η(t) (Hz)');
title('Random Walk Component (η)');

% --- 5. Instantaneous Frequency Deviation
subplot(3,2,5);
plot(t_vec*1e6, df_vec, 'r');
xlabel('Time (µs)'); ylabel('Δf (Hz)');
title('Total Frequency Deviation of Noisy Clock');

sgtitle('Clock Phase Model — Full Diagnostic Comparison');

%% METRICS: Phase Error and Frequency Drift
% Phase Error
mean_phi_err = mean(phi_error);
std_phi_err  = std(phi_error);

mean_coarse_err = mean(coarse_error);
std_coarse_err  = std(coarse_error);

mean_fine_err = mean(fine_error);
std_fine_err  = std(fine_error);

% Frequency Deviation
mean_df = mean(df_vec);
std_df  = std(df_vec);

% --- Console Output ---
fprintf('\n--- Phase Error Statistics ---\n');
fprintf('Coarse Phase Error  : Mean = %.3e rad, Std = %.3e rad\n', mean_coarse_err, std_coarse_err);
fprintf('Fine Phase Error    : Mean = %.3e rad, Std = %.3e rad\n', mean_fine_err, std_fine_err);

fprintf('\n--- Frequency Deviation ---\n');
fprintf('Total Frequency Deviation : Mean = %.3f Hz, Std = %.3f Hz\n', mean_df, std_df);

