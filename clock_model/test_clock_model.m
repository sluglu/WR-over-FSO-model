clear; clc;

%% PARAMETERS
f0 = 125e6;
t0 = 1000;
dt = 1e-12;
N = 5000;

% Noisy profile
params_noisy = struct(...
    'delta_f0', 1e3, ...
    'alpha', 1000, ...
    'sigma_rw', 5000, ...
    'sigma_jitter', 1000 ...
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

clk_noisy = master_clock(f0, t0, np_noisy);
clk_ideal = master_clock(f0, t0, np_ideal);

%% BUFFERS
t_vec = (0:N-1)*dt + t0;

phi_noisy = zeros(1, N);
phi_ideal = zeros(1, N);
phi_error = zeros(1, N);

eta_vec = zeros(1, N);
df_vec = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    % Ideal
    phi_ideal(i) = clk_ideal.phi;
    phi_noisy(i) = clk_noisy.phi;
    phi_error(i) = clk_noisy.phi - clk_ideal.phi;

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
% --- 1. Phase ideal vs noisy
subplot(3,2,1);
plot(t_vec, phi_ideal, 'b--', t_vec, phi_noisy, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Ideal','Noisy'); title('Phase Evolution');

% --- 2. Phase error 
subplot(3,2,2);
plot(t_vec, phi_error, 'b--');
xlabel('Time'); ylabel('Phase Error (rad)');
title('Phase Error');

% --- 3. Random Walk η(t)
subplot(3,2,3);
plot(t_vec, eta_vec, 'b');
xlabel('Time'); ylabel('η(t) (Hz)');
title('Random Walk Component (η)');

% --- 4. Instantaneous Frequency Deviation
subplot(3,2,4);
plot(t_vec, df_vec, 'r');
xlabel('Time'); ylabel('Δf (Hz)');
title('Total Frequency Deviation of Noisy Clock');

% --- 5. Signal

ideal_signal = cos(2*pi*clk_ideal.f0*t_vec + phi_ideal);
noisy_signal = cos(2*pi*clk_noisy.f0*t_vec + phi_noisy);

subplot(3,2,[5,6]);
plot(t_vec, ideal_signal, 'b--', t_vec, noisy_signal, 'r');
xlabel('Time'); ylabel('Signal');
legend('Ideal','Noisy'); title('Signal');



sgtitle('Clock Phase Model — Full Diagnostic Comparison');

%% METRICS: Phase Error and Frequency Drift
% Phase Error
mean_phi_err = mean(phi_error);
std_phi_err  = std(phi_error);

% Frequency Deviation
mean_df = mean(df_vec);
std_df  = std(df_vec);

% --- Console Output ---
fprintf('\n--- Phase Error Statistics ---\n');
fprintf('Phase Error  : Mean = %.3e rad, Std = %.3e rad\n', mean_phi_err, std_phi_err);

fprintf('\n--- Frequency Deviation ---\n');
fprintf('Total Frequency Deviation : Mean = %.3f Hz, Std = %.3f Hz\n', mean_df, std_df);

