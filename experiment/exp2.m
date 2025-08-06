clear; clc; close all;

%% Simulation Parameters
dt_ptp = 0.001;            % PTP simulation time step [s]
dt_orbital = 1;            % Orbital position update interval [s]
f0 = 125e6;                % Reference frequency [Hz]
sync_interval = 0.5;       % PTP sync interval [s]
min_msg_interval = 1e-6;   % Minimum time between message processed in same cyle (e.g. sync and followup) [s]
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

% %% Run simulation
% scenario_idx = 1; % Select scenario to simulate
% scenario = scenarios(scenario_idx, :);
% fprintf('Simulating scenario: %s\n', scenario{1});
% results = simulate_ptp_orbital(sim_duration, ptp_params, scenario);
% save_filename = sprintf('results/exp2_PTP_orbital_sim_%s.mat', strrep(scenario{1}, ' ', '_'));
% save(save_filename, "-fromstruct",results);
% fprintf('\nResults saved to %s\n', save_filename);

%% Run simulation (all scenarios)
parfor i = 1:size(scenarios, 1)
    scenario_idx = i; % Select scenario to simulate
    scenario = scenarios(scenario_idx, :);
    fprintf('Simulating scenario: %s\n', scenario{1});
    results = simulate_ptp_orbital(sim_duration, ptp_params, scenario);
    save_filename = sprintf('results/exp2_PTP_orbital_sim_%s.mat', strrep(scenario{1}, ' ', '_'));
    save(save_filename, "-fromstruct", results);
    fprintf('\nResults saved to %s\n', save_filename);
end

%% Plot Results
scenario_idx = 3; % Select scenario to simulate
scenario = scenarios(scenario_idx, :);
save_filename = sprintf('results/exp2_PTP_orbital_sim_%s.mat', strrep(scenario{1}, ' ', '_'));
results = load(save_filename);
plot_PTP_orbital_scenario(results);