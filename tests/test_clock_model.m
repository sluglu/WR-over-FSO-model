%% Example: Using Power Law Noise in Clock Models
clear; clc;

%% Power Law Noise Parameters
% Example 1: High-Performance OCXO (100Mhz OX-249)
slave_f0 = 100e6;
ocxo_params = struct(...
    'delta_f0', (rand() * 2 * 50) - 50, ...
    'alpha', (rand() * 2 * 1.58e-6) - 1.58e-6, ...
    'power_law_coeffs', [0, 4.62e-23, 1.58e-25, 0, 1.0e-32]);

% Example 2: Rubidium Atomic Clock (10 MHz CSAC-SA45.)
master_f0 = 10e6;
rubidium_params = struct( ...
        'delta_f0', (rand() * 2 * 5e-11) - 5e-11, ...
        'alpha', (rand() * 2 * 3.15e-9) - 3.15e-9, ...
        'power_law_coeffs', [0, 0, 1.8e-19, 0, 2.0e-28]);

%% Create Clocks with Power Law Noise
% Create master with high-quality rubidium clock
master_clock = WRClock(master_f0, 0, NoiseProfile(rubidium_params));
master = MasterNode(master_clock, MasterFSM(1, false));

% Create slave with OCXO
slave_clock = WRClock(slave_f0, 0, NoiseProfile(ocxo_params));
slave = SlaveNode(slave_clock, SlaveFSM(false));

%% Simulation Parameters
dt = 0.1;  % 1 ms time step
sim_duration = 3600;  % 1 hour simulation
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
plot(times, master_freq/master_f0, 'b-', 'LineWidth', 1);
hold on;
plot(times, slave_freq/slave_f0, 'r-', 'LineWidth', 1);
xlabel('Time [s]');
ylabel('Frequency [Hz/Hz]');
title('Clock Frequency Evolution');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 2: Frequency Difference
subplot(3,2,2);
plot(times, freq_difference, 'g-', 'LineWidth', 1);
xlabel('Time [s]');
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

% subplot(3,2,4);
% loglog(freq_axis, psd_master, 'b-', 'LineWidth', 1);
% hold on;
% loglog(freq_axis, psd_slave, 'r-', 'LineWidth', 1);
% xlabel('Frequency [Hz]');
% ylabel('Power Spectral Density [Hz²/Hz]');
% title('Frequency Noise PSD');
% legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
% grid on;

% Plot 4: Empirical Phase Noise from Simulation Data
subplot(3,2,4);
valid_indices = 2:length(freq_axis);
f = freq_axis(valid_indices); % The valid frequency offsets
psd_f_master = psd_master(valid_indices);
psd_f_slave = psd_slave(valid_indices);
psd_phi_master = psd_f_master ./ (f.^2);
psd_phi_slave = psd_f_slave ./ (f.^2);
L_f_dB_master = 10 * log10(0.5 * psd_phi_master);
L_f_dB_slave = 10 * log10(0.5 * psd_phi_slave);
semilogx(f, L_f_dB_master, 'b-', 'LineWidth', 1);
hold on;
semilogx(f, L_f_dB_slave, 'r-', 'LineWidth', 1);
xlabel('Frequency Offset f [Hz]');
ylabel('Phase Noise L(f) [dBc/Hz]');
title('Empirical Phase Noise from Simulation'); % Clarify it's from the data
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 5: Histogram of Frequency Deviations  
subplot(3,2,5);
histogram((master_freq - master_f0)/master_f0 * 1e9, 50, 'Normalization', 'probability', ...
          'FaceAlpha', 0.7, 'FaceColor', 'blue');
hold on;
histogram((slave_freq - slave_f0)/slave_f0 * 1e9, 50, 'Normalization', 'probability', ...
          'FaceAlpha', 0.7, 'FaceColor', 'red');
xlabel('Fractional Frequency Deviation [ppb]');
ylabel('Probability');
title('Frequency Deviation Distribution');
legend('Master (Rb)', 'Slave (OCXO)', 'Location', 'best');
grid on;

% Plot 6: Phase Difference Evolution
master_phase = cumsum((master_freq - master_f0) * dt);
slave_phase = cumsum((slave_freq - slave_f0) * dt);
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
fprintf('  Fractional stability: %.3e\n', std(master_freq)/master_f0);

fprintf('\nSlave Clock (OCXO):\n');
fprintf('  Mean frequency: %.9f Hz\n', mean(slave_freq));
fprintf('  Std deviation: %.3e Hz\n', std(slave_freq));
fprintf('  Fractional stability: %.3e\n', std(slave_freq)/slave_f0);

fprintf('\nFrequency Difference:\n');
fprintf('  Mean difference: %.3e Hz\n', mean(freq_difference));
fprintf('  Std deviation: %.3e Hz\n', std(freq_difference));
fprintf('  Max deviation: %.3e Hz\n', max(abs(freq_difference)));