clear; clc; close all;

%% Sim parameters
dt = 20; %in seconds
sim_duration = 4; %in hours

%% Constants
deg = pi/180;
rE = 6371e3;             % Earth radius [m]
c = 299792458;           % Speed of light [m/s]

%% Scenario definitions
scenarios = {
    "StarLink V1 like",                     rE+550e3, rE+550e3, 53*deg,  53*deg,     0,         0,       0,       70*deg;
    "Opposite Inclination",                 rE+550e3, rE+550e3, 45*deg, -45*deg,     0,         0,       0,       0;
    "Walker Delta (shared plane)",          rE+1200e3,rE+1200e3,55*deg,  55*deg,     0,         0,       0,      36*deg;
    "Polar Orbit (counter-rotating)",       rE+800e3, rE+800e3, 90*deg, -90*deg,     0,         0,       0,       0;
};

% "Polar Orbit (counter-rotating)",       rE+800e3, rE+800e3, 90*deg, -90*deg,     0,         0,       0,       0;

%% Sim
n_scenarios = size(scenarios,1);
tspan = 0:dt:sim_duration*3600;
N = length(tspan);
colors = lines(n_scenarios);

figure('Position', [100, 100, 1400, 900]);

for s = 1:n_scenarios
    %% Unpack scenario
    name = scenarios{s,1};
    r1_val = scenarios{s,2}; r2_val = scenarios{s,3};
    i1 = scenarios{s,4};     i2 = scenarios{s,5};
    th1 = scenarios{s,6};    th2 = scenarios{s,7};
    omega1 = scenarios{s,8}; omega2 = scenarios{s,9};

    params1 = struct('r', r1_val, 'i', i1, 'theta0', th1, 'RAAN', omega1);
    params2 = struct('r', r2_val, 'i', i2, 'theta0', th2, 'RAAN', omega2);

    [r1, r2] = generate_position_functions(params1, params2);

    %% LOS Intervals and Flags
    [los_intervals, los_flags]  = compute_los_intervals(r1, r2, tspan);

    %% Simulate positions and delays
    pos1 = zeros(3, N);
    pos2 = zeros(3, N);
    delays = NaN(1, N);

    for k = 1:N
        t = tspan(k);
        pos1(:,k) = r1(t);
        pos2(:,k) = r2(t);
        if los_flags(k)
            try
                dt = compute_propagation_delay(r1, r2, t, NaN);
                delays(k) = dt;
            catch
                delays(k) = NaN;
            end
        end
    end

    %% Subplot indices
    i3d = (s-1)*3 + 1;
    ilos = i3d + 1;
    idel = i3d + 2;

    %% 3D Plot
    subplot(n_scenarios,3,i3d); hold on;
    plot3(pos1(1,:), pos1(2,:), pos1(3,:), '-', 'Color', colors(s,:), 'LineWidth', 1.2);
    plot3(pos2(1,:), pos2(2,:), pos2(3,:), '--', 'Color', colors(s,:), 'LineWidth', 1.2);

    % Earth
    [xe, ye, ze] = sphere(50);
    surf(xe*rE, ye*rE, ze*rE, 'FaceAlpha', 0.1, 'EdgeColor','none', 'FaceColor', [0.6 0.6 1]);

    % LOS lines
    for intv = 1:size(los_intervals,1)
        idxs = find(tspan >= los_intervals(intv,1) & tspan <= los_intervals(intv,2));
        for k = idxs
            plot3([pos1(1,k), pos2(1,k)], [pos1(2,k), pos2(2,k)], [pos1(3,k), pos2(3,k)], 'g-', 'LineWidth', 0.5);
        end
    end

    % View setup
    axis equal; grid on;
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(sprintf('[%d] %s', s, name), 'FontWeight', 'bold', 'Interpreter', 'none');    

    %% Orbital parameters text
    % Get reference point (bug: break if n_scenarios ~= 4)
    ax = gca;
    ax_pos = get(ax, 'Position');  % [left bottom width height]
    x_norm = ax_pos(1) - 0.4/n_scenarios;
    x_norm = max(0, x_norm);
    y_norm1 = ax_pos(2) + 2*ax_pos(4)/3;
    y_norm2 = ax_pos(2);
    

    % Define orbital parameters text
    str1 = sprintf(['\\bfOrbit 1:\\rm\n', ...
                'Radius: %.0f km\n', ...
                'Inclination: %.1f°\n', ...
                'RAAN: %.1f°\n', ...
                'θ₀: %.1f°'], ...
                params1.r/1e3, rad2deg(params1.i), rad2deg(params1.RAAN), rad2deg(params1.theta0));

    str2 = sprintf(['\\bfOrbit 2:\\rm\n', ...
                'Radius: %.0f km\n', ...
                'Inclination: %.1f°\n', ...
                'RAAN: %.1f°\n', ...
                'θ₀: %.1f°'], ...
                params2.r/1e3, rad2deg(params2.i), rad2deg(params2.RAAN), rad2deg(params2.theta0));

    % Add annotation to figure (outside axes)
    annotation('textbox', [x_norm, y_norm1, 0.1, 0.1], ...
        'String', str1, ...
        'FontSize', min(20,40/n_scenarios), ...
        'EdgeColor', 'none', ...
        'Interpreter', 'tex', ...
        'FitBoxToText','on');

    annotation('textbox', [x_norm, y_norm2, 0.1, 0.1], ...
        'String', str2, ...
        'FontSize', min(20,40/n_scenarios), ...
        'EdgeColor', 'none', ...
        'Interpreter', 'tex', ...
        'FitBoxToText','on');

    %% LOS over time
    subplot(n_scenarios,3,ilos);
    area(tspan/60, los_flags, 'FaceColor', colors(s,:), 'FaceAlpha', 0.3, 'EdgeColor', colors(s,:));
    ylim([-0.1, 1.1]); grid on;
    xlabel('Time [min]'); ylabel('LOS');
    title('LOS over Time');

    %% Delay over time
    subplot(n_scenarios,3,idel);
    plot(tspan/60, delays, 'Color', colors(s,:), 'LineWidth', 1.5);
    xlabel('Time [min]'); ylabel('Delay [s]');
    title('Propagation Delay'); grid on;
end