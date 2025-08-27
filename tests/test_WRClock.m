clear; clc;

%% PARAMETERS
f0 = 125e6;
t0 = 0;
dt = 1e-2;
N = 5000;

ocxo_params = struct(...
    'power_law_coeffs', [8e-24, 1e-27, 1e-28, 4e-32, 2e-34] ...  % Typical OCXO values
);

%% INIT CLOCKS
np_noisy = NoiseProfile(ocxo_params);

clk_noisy = SlaveClock(f0, t0, np_noisy);
clk_ideal = MasterClock(f0, t0, NoiseProfile());

master = MasterNode(clk_ideal, MasterFSM());
slave = SlaveNode(clk_noisy, SlaveFSM());

%% BUFFERS
t_vec = (0:N-1)*dt + t0;

phi_noisy = zeros(1, N);
phi_ideal = zeros(1, N);
phi_error = zeros(1, N);

df_vec = zeros(1, N);

%% SIMULATION LOOP
for i = 1:N
    phi_ideal(i) = master.get_phi();
    phi_noisy(i) = slave.get_phi();
    phi_error(i) = slave.get_phi() - master.get_phi();

    df_vec(i) = slave.get_freq() - master.get_freq(); 

    % Advance clocks
    slave = slave.advance_time(dt);
    master = master.advance_time(dt);
end

%% PLOTS
figure('Name', 'Clock Phase Component Breakdown', 'Position', [100 -100 1300 1000]);
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

% --- 6. Signal

phi_ideal_adj = phi_ideal - phi_ideal(1);
phi_noisy_adj = phi_noisy - phi_noisy(1);

ideal_signal = cos(phi_ideal_adj);
noisy_signal = cos(phi_noisy_adj);

cycles_to_show = 5;
samples_per_cycle = round(1 / (f0 * dt));
zoom_idx = 1000 : 1000 + cycles_to_show * samples_per_cycle;
zoom_idx = zoom_idx(zoom_idx <= N);  % Prevent overflow

subplot(2,3,[4,6]);
plot(t_vec(zoom_idx), ideal_signal(zoom_idx), 'b--', ...
     t_vec(zoom_idx), noisy_signal(zoom_idx), 'r');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Ideal','Noisy'); title('Signal (Zoomed In)');


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

