clear; clc;

%% PARAMETERS
f0 = 125e6;
t0 = 0;
dt = 1e-10;
N = 5000;

% Noisy profile
params_noisy = struct(...
    'delta_f0', 50, ...
    'alpha', 100, ...
    'sigma_rw', 500, ...
    'sigma_jitter', 20 ...
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

df_vec = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    phi_ideal(i) = clk_ideal.phi;
    phi_noisy(i) = clk_noisy.phi;
    phi_error(i) = clk_noisy.phi - clk_ideal.phi;

    df_vec(i) = clk_noisy.f - clk_ideal.f; 
    eta_vec(i) = clk_noisy.noise_profile.eta;
    t_accum(i) = clk_noisy.noise_profile.t_accum;

    % Advance clocks
    clk_noisy = clk_noisy.advance(dt);
    clk_ideal = clk_ideal.advance(dt);
end

%% PLOTS
figure('Name', 'Clock Phase Component Breakdown', 'Position', [100 100 1300 1000]);
% --- 1. Phase ideal vs noisy
subplot(2,3,1);
plot(t_vec, phi_ideal, 'b--', t_vec, phi_noisy, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Ideal','Noisy'); title('Phase Evolution');

% --- 2. Phase error 
subplot(2,3,2);
plot(t_vec, phi_error, 'b--');
xlabel('Time'); ylabel('Phase Error (rad)');
title('Phase Error');


% --- 3. Instantaneous Frequency Deviation
subplot(2,3,3);
plot(t_vec, df_vec, 'r');
xlabel('Time'); ylabel('Δf (Hz)');
title('Frequency Deviation of Noisy Clock');

% --- 4. Cumulative jitter
subplot(2,3,4);
plot(t_vec, eta_vec);
xlabel('Time'); ylabel('\eta (Hz)');
title('Cumulative Jitter (Random Walk) Component');


% --- 5. Drift component
subplot(2,3,5);
plot(t_vec,  params_noisy.alpha * t_accum);
xlabel('Time'); ylabel('\alpha * t (Hz)');
title('Drift Component');

% --- 6. Signal

phi_ideal_adj = phi_ideal - phi_ideal(1);
phi_noisy_adj = phi_noisy - phi_noisy(1);

ideal_signal = cos(phi_ideal_adj);
noisy_signal = cos(phi_noisy_adj);

cycles_to_show = 5;
samples_per_cycle = round(1 / (f0 * dt));
zoom_idx = 1000 : 1000 + cycles_to_show * samples_per_cycle;
zoom_idx = zoom_idx(zoom_idx <= N);  % Prevent overflow

subplot(2,3,6);
plot(t_vec(zoom_idx), ideal_signal(zoom_idx), 'b--', ...
     t_vec(zoom_idx), noisy_signal(zoom_idx), 'r');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Ideal','Noisy'); title('Signal (Zoomed In)');



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
fprintf('Frequency Deviation : Mean = %.3f Hz, Std = %.3f Hz\n', mean_df, std_df);

