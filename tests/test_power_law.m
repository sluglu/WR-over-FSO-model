%% Example: Using Power Law Noise in Clock Models
clear; clc;

%% Power Law Noise Parameters
% Define h coefficients according to IEEE Std 1139-2008
% h_coeffs = [h_{-2}, h_{-1}, h_0, h_1, h_2]

% Example 1: High-Performance OCXO
% Should have a flicker floor around 1e-12, with drift starting to dominate > 100s.
ocxo_params = struct(...
    'power_law_coeffs', [ ...
        5.0e-27, ...  % h_{-2}: Corresponds to a realistic drift/aging rate
        2.0e-24, ...  % h_{-1}: Flicker floor, sigma_y ~1.6e-12
        1.5e-25, ...  % h_{0}: White FM, dominates at short tau
        6.0e-26, ...  % h_{1}: Flicker PM
        1.5e-27  ...  % h_{2}: White PM
    ] ...
);

% Example 2: Rubidium Atomic Clock
% Much better long-term stability (smaller h_{-2}, h_{-1}), but potentially noisier at very short tau.
rubidium_params = struct(...
    'power_law_coeffs', [ ...
        2.0e-30, ...  % h_{-2}: Very low random walk, excellent long-term stability
        8.0e-29, ...  % h_{-1}: Very low flicker floor, sigma_y ~ 1e-14
        2.0e-25, ...  % h_{0}: White FM, similar to OCXO
        6.0e-23, ...  % h_{1}: Flicker PM
        2.0e-21  ...  % h_{2}: White PM, often higher in atomic standards
    ] ...
);

%% Create Clocks with Power Law Noise
f0 = 125e6;  % 125 MHz reference
t0 = 0;

% Create master with high-quality rubidium clock
master_clock = MasterClock(f0, t0, NoiseProfile(rubidium_params));
master = MasterNode(master_clock, MasterFSM(1, false));

% Create slave with OCXO
slave_clock = SlaveClock(f0, t0, NoiseProfile(ocxo_params));
slave = SlaveNode(slave_clock, SlaveFSM(false));

%% Simulation Parameters
dt = 0.001;  % 1 ms time step
sim_duration = 60;  % 1 hour simulation
N = ceil(sim_duration / dt);

% Pre-allocate arrays
times = (0:N-1) * dt;
master_freq = zeros(1, N);
slave_freq = zeros(1, N);
freq_difference = zeros(1, N);

%% Run Simulation
fprintf('Simulating %d samples over %.1f hours...\n', N, sim_duration/3600);

for i = 1:N
    % Record frequencies
    master_freq(i) = master.get_freq();
    slave_freq(i) = slave.get_freq();
    freq_difference(i) = slave_freq(i) - master_freq(i);
    
    % Advance time
    master = master.advance_time(dt);
    slave = slave.advance_time(dt);
    
    % Progress indicator
    if mod(i, floor(N/10)) == 0
        fprintf('Progress: %.0f%%\n', 100*i/N);
    end
end

%% Analysis and Plotting
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Frequency vs Time
subplot(3,2,1);
plot(times/3600, (master_freq - f0)/f0 * 1e9, 'b-', 'LineWidth', 1);
hold on;
plot(times/3600, (slave_freq - f0)/f0 * 1e9, 'r-', 'LineWidth', 1);
xlabel('Time [hours]');
ylabel('Fractional Frequency [ppb]');
title('Clock Frequency Evolution');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 2: Frequency Difference
subplot(3,2,2);
plot(times/3600, freq_difference, 'g-', 'LineWidth', 1);
xlabel('Time [hours]');
ylabel('Frequency Difference [Hz]');
title('Frequency Difference (Slave - Master)');
grid on;

% Plot 3: Allan Deviation Calculation
tau_values = logspace(0, 4, 50);  % 1 s to 10,000 s averaging times
master_np = master.get_noise_profile();
slave_np = slave.get_noise_profile();

allan_dev_master = zeros(size(tau_values));
allan_dev_slave = zeros(size(tau_values));

for j = 1:length(tau_values)
    allan_dev_master(j) = master_np.allan_deviation_estimate(tau_values(j));
    allan_dev_slave(j) = slave_np.allan_deviation_estimate(tau_values(j));
end

subplot(3,2,3);
loglog(tau_values, allan_dev_master, 'b-', 'LineWidth', 2);
hold on;
loglog(tau_values, allan_dev_slave, 'r-', 'LineWidth', 2);
xlabel('Averaging Time τ [s]');
ylabel('Allan Deviation σ_y(τ)');
title('Theoretical Allan Deviation');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 4: Power Spectral Density (approximation)
[psd_master, freq_axis] = pwelch(master_freq - mean(master_freq), [], [], [], 1/dt);
[psd_slave, ~] = pwelch(slave_freq - mean(slave_freq), [], [], [], 1/dt);

subplot(3,2,4);
loglog(freq_axis, psd_master, 'b-', 'LineWidth', 1);
hold on;
loglog(freq_axis, psd_slave, 'r-', 'LineWidth', 1);
xlabel('Frequency [Hz]');
ylabel('Power Spectral Density [Hz²/Hz]');
title('Frequency Noise PSD');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 5: Histogram of Frequency Deviations  
subplot(3,2,5);
histogram((master_freq - f0)/f0 * 1e9, 50, 'Normalization', 'probability', ...
          'FaceAlpha', 0.7, 'FaceColor', 'blue');
hold on;
histogram((slave_freq - f0)/f0 * 1e9, 50, 'Normalization', 'probability', ...
          'FaceAlpha', 0.7, 'FaceColor', 'red');
xlabel('Fractional Frequency Deviation [ppb]');
ylabel('Probability');
title('Frequency Deviation Distribution');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 6: Phase Difference Evolution
master_phase = cumsum((master_freq - f0) * dt);
slave_phase = cumsum((slave_freq - f0) * dt);
phase_diff = slave_phase - master_phase;

subplot(3,2,6);
plot(times/3600, phase_diff, 'g-', 'LineWidth', 1);
xlabel('Time [hours]');
ylabel('Phase Difference [rad]');
title('Cumulative Phase Difference');
grid on;

sgtitle('Power Law Clock Noise Simulation Results', 'FontSize', 14, 'FontWeight', 'bold');

%% Summary Statistics
fprintf('\n=== SIMULATION RESULTS ===\n');
fprintf('Master Clock (Rubidium):\n');
fprintf('  Mean frequency: %.9f Hz\n', mean(master_freq));
fprintf('  Std deviation: %.3e Hz\n', std(master_freq));
fprintf('  Fractional stability: %.3e\n', std(master_freq)/f0);

fprintf('\nSlave Clock (OCXO):\n');
fprintf('  Mean frequency: %.9f Hz\n', mean(slave_freq));
fprintf('  Std deviation: %.3e Hz\n', std(slave_freq));
fprintf('  Fractional stability: %.3e\n', std(slave_freq)/f0);

fprintf('\nFrequency Difference:\n');
fprintf('  Mean difference: %.3e Hz\n', mean(freq_difference));
fprintf('  Std deviation: %.3e Hz\n', std(freq_difference));
fprintf('  Max deviation: %.3e Hz\n', max(abs(freq_difference)));

% %% Compare with Legacy Model
% % For comparison, create equivalent legacy parameters
% legacy_params = struct(...
%     'delta_f0', 0, ...
%     'alpha', 1e-9, ...        % Small linear drift
%     'sigma_rw', 1e-6, ...     % Random walk
%     'sigma_jitter', 5e-6 ...  % White noise
% );
% 
% legacy_clock = SlaveClock(f0, t0, NoiseProfile(legacy_params));
% legacy_node = SlaveNode(legacy_clock, SlaveFSM(false));
% 
% legacy_freq = zeros(1, min(1000, N));  % Shorter simulation for comparison
% for i = 1:length(legacy_freq)
%     legacy_freq(i) = legacy_node.get_freq();
%     legacy_node = legacy_node.advance_time(dt);
% end
% 
% figure('Position', [100, 300, 800, 400]);
% plot((0:length(legacy_freq)-1)*dt/60, (legacy_freq - f0)/f0 * 1e9, 'k--', 'LineWidth', 2);
% hold on;
% plot(times(1:length(legacy_freq))/60, (slave_freq(1:length(legacy_freq)) - f0)/f0 * 1e9, 'r-', 'LineWidth', 1);
% xlabel('Time [minutes]');
% ylabel('Fractional Frequency [ppb]');
% title('Power Law vs Legacy Noise Model Comparison');
% legend('Legacy Model', 'Power Law Model', 'Location', 'best');
% grid on;