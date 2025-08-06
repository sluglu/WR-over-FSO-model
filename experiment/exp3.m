clear; clc; close all;

%% Simulation Parameters
dt_ptp = 0.001;            % PTP simulation time step [s]
dt_orbital = 1;            % Orbital position update interval [s]
f0 = 125e6;                % Reference frequency [Hz]
sync_interval = 0.5;       % PTP sync interval [s]
min_msg_interval = 1e-3;   % Minimum time between message processed in same cyle (e.g. sync and followup) [s]
sim_duration = 1;          % Total simulation duration [hours]
verbose = false;
min_los_duration = 1;      % Minimum LOS duration to simulate PTP [s]

ptp_params = struct('dt_ptp', dt_ptp, 'dt_orbital', dt_orbital, 'f0', f0, ...
                   'sync_interval', sync_interval, 'min_msg_interval', ...
                   min_msg_interval, 'verbose', verbose, 'min_los_duration', min_los_duration);

deg = pi/180;
rE = 6371e3;

scenarios = {
    "StarLink V1 like",                     rE+550e3, rE+550e3, 53*deg,  53*deg,     0,         0,       0,       70*deg;
    "Opposite Inclination",                 rE+550e3, rE+550e3, 45*deg, -45*deg,     0,         0,       0,       0;
    "Walker Delta (shared plane)",          rE+1200e3,rE+1200e3,55*deg,  55*deg,     0,         0,       0,      36*deg;
    "Polar Orbit (counter-rotating)",       rE+800e3, rE+800e3, 90*deg, -90*deg,     0,         0,       0,       0;
};

%% Run simulation
sync_intervals = [0.1 0.5 1 5];
scenario_idx = 1; % Select scenario to simulate
scenario = scenarios(scenario_idx, :);

for i = 1:length(sync_intervals)
    sync_interval = sync_intervals(i);
    ptp_param = ptp_params;
    ptp_param.sync_interval = sync_interval;
    fprintf('Simulating scenario: %s with sync_intervals: %d\n', scenario{1}, sync_interval);
    results = simulate_ptp_orbital(sim_duration, ptp_param, scenario);
    % Save Results
    save_filename = sprintf('results/exp3_PTP_orbital_sim_%s_sync_intervals/exp3_PTP_orbital_sim_%s_sync_interval_%d.mat', strrep(scenario{1}, ' ', '_'), strrep(scenario{1}, ' ', '_'), sync_interval);
    save(save_filename, "-fromstruct", results);
    fprintf('\nResults saved to %s\n', save_filename);
end

%% Plot Results
results = [];
means = [];
for i = 1:length(sync_intervals)
    sync_interval = sync_intervals(i);
    save_filename = sprintf('results/exp3_PTP_orbital_sim_%s_sync_intervals/exp3_PTP_orbital_sim_%s_sync_interval_%d.mat', strrep(scenario{1}, ' ', '_'), trrep(scenario{1}, ' ', '_'), sync_interval);
    results(i) = load(save_filename);
    means(i) = abs(mean(results(i).real_offset));
end
figure;   
plot(sync_intervals, means, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Real Clock Offsset');
ylabel('Clock Offset [s]');
xlabel('Sync Intervals [s]');
title('Clock Synchronization Performance vs Sync Intervals');
legend('show', 'Location', 'best');
grid on;
hold off;

