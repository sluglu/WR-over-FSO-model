clear; clc; close all;

%% Constants
deg = pi/180;
rE = 6371e3;

%% Simulation Parameters
dt_ptp = 0.001;            % PTP simulation time step [s]
dt_orbital = 1;            % Orbital position update interval [s]
sim_duration = 1;          % Total simulation duration [hours]
min_los_duration = 1;      % Minimum LOS duration to simulate PTP [s]

%% PTP Parameters
f0 = 125e6;                % Reference frequency [Hz]
sync_interval = 0.5;       % PTP sync interval [s]
t0 = 0;
initial_time_offset = 0;
master_noise_profile = NoiseProfile(struct('delta_f0', 0, 'alpha', 0, 'sigma_rw', 0, 'sigma_jitter', 0));
slave_noise_profile = NoiseProfile(struct('delta_f0', 0, 'alpha', 0, 'sigma_rw', 0, 'sigma_jitter', 0));
offset_correction = false;
syntonization = false;
min_msg_interval = 1e-6;   % Minimum time between message processed in same cyle (e.g. sync and followup) [s]
verbose = false;

%% Scenario Parameters
scenarios = {
    "StarLink V1 like",                     rE+550e3, rE+550e3, 53*deg,  53*deg,     0,         0,       0,       70*deg;
    "Opposite Inclination",                 rE+550e3, rE+550e3, 45*deg, -45*deg,     0,         0,       0,       0;
    "Walker Delta (shared plane)",          rE+1200e3,rE+1200e3,55*deg,  55*deg,     0,         0,       0,      36*deg;
    "Polar Orbit (counter-rotating)",       rE+800e3, rE+800e3, 90*deg, -90*deg,     0,         0,       0,       0;
};

scenario_idx = 1; % Select scenario to simulate

%% Packing parameters
sim_params = struct('dt_ptp', dt_ptp, 'dt_orbital', dt_orbital, 'sim_duration', sim_duration, 'min_los_duration', min_los_duration);

ptp_params = struct('f0', f0, 'sync_interval', sync_interval, 'min_msg_interval', min_msg_interval, 'verbose', verbose, ...
                   'master_noise_profile', master_noise_profile, 'slave_noise_profile', slave_noise_profile, ...
                   'offset_correction', offset_correction, 'syntonization', syntonization, 't0', t0, ...
                   'initial_time_offset', initial_time_offset);

scenario = scenarios(scenario_idx, :);
save_filename = sprintf('experiment/exp2/results/exp2_PTP_orbital_sim_%s.mat', strrep(scenario{1}, ' ', '_'));

%% Run simulation
fprintf('Simulating scenario: %s\n', scenario{1});
results = simulate_ptp_orbital(sim_params, ptp_params, scenario);
save(save_filename, "-fromstruct",results);
fprintf('\nResults saved to %s\n', save_filename);

% % Run simulation (all scenarios)
% parfor i = 1:size(scenarios, 1)
%     scenario_idx = i; % Select scenario to simulate
%     scenario = scenarios(scenario_idx, :);
%     fprintf('Simulating scenario: %s\n', scenario{1});
%     results = simulate_ptp_orbital(sim_params, ptp_params, scenario);
%     save_filename = sprintf('results/exp2_PTP_orbital_sim_%s.mat', strrep(scenario{1}, ' ', '_'));
%     save(save_filename, "-fromstruct", results);
%     fprintf('\nResults saved to %s\n', save_filename);
% end

%% Plot Results
results = load(save_filename);
plot_PTP_orbital_scenario(results);