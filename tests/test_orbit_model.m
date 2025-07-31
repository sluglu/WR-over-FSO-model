clear; clc; close all;

%% Constants
deg = pi/180;
rE = 6371e3;             % Earth radius [m]
c = 299792458;           % Speed of light [m/s]
tspan = 0:20:4*3600;     % 4 hours at 20s resolution
N = length(tspan);
colors = lines(4);

%% Updated Scenario definitions
scenarios = {
    "Low Alt Diff, Same Plane",             rE+550e3, rE+580e3, 53*deg, 53*deg, 0,      40*deg;
    "Cross Plane (Dynamic LOS)",            rE+550e3, rE+580e3, 20*deg, 70*deg, 0,      135*deg;
    "Same Radius, Inclined Anti-phase",     rE+550e3, rE+550e3, 53*deg, 63*deg, 0,      180*deg;
    "Opposite Inclination",                 rE+550e3, rE+550e3, 45*deg, -45*deg, 0,     0;
};

figure('Position', [100, 100, 1400, 900]);

for s = 1:size(scenarios,1)
    %% Unpack scenario
    name = scenarios{s,1};
    r1_val = scenarios{s,2}; r2_val = scenarios{s,3};
    i1 = scenarios{s,4};     i2 = scenarios{s,5};
    th1 = scenarios{s,6};    th2 = scenarios{s,7};

    params1 = struct('r', r1_val, 'i', i1, 'theta0', th1);
    params2 = struct('r', r2_val, 'i', i2, 'theta0', th2);

    [r1, r2] = generate_position_functions(params1, params2);

    %% LOS Intervals and Flags
    los_intervals = compute_los_intervals(r1, r2, [tspan(1), tspan(end)], 20);
    los_flags = false(1, N);
    for intv = 1:size(los_intervals, 1)
        t_start = los_intervals(intv, 1);
        t_end   = los_intervals(intv, 2);
        idxs = find(tspan >= t_start & tspan <= t_end);
        los_flags(idxs) = true;
    end

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
                [dt, ~, ~, ~] = compute_propagation_delay(r1, r2, t);
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

    %% --- 3D Plot ---
    subplot(4,3,i3d); hold on;
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
    view(30, 20);
    axis equal; grid on;
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(sprintf('[%d] %s', s, name), 'FontWeight', 'bold', 'Interpreter', 'none');

    % Display orbital parameters (bottom-left corner)
    x_pos = min(pos1(1,:));
    y_pos = min(pos1(2,:));
    z_pos = min(pos1(3,:));
    text(x_pos, y_pos, z_pos, ...
        sprintf(['r₁=%.0fkm, i₁=%.0f°, θ₁₀=%.0f°\n' ...
                 'r₂=%.0fkm, i₂=%.0f°, θ₂₀=%.0f°'], ...
            r1_val/1e3, rad2deg(i1), rad2deg(th1), ...
            r2_val/1e3, rad2deg(i2), rad2deg(th2)), ...
        'FontSize', 8, 'HorizontalAlignment','left', 'VerticalAlignment','bottom');

    %% --- LOS over time ---
    subplot(4,3,ilos);
    area(tspan/60, los_flags, 'FaceColor', colors(s,:), 'FaceAlpha', 0.3, 'EdgeColor', colors(s,:));
    ylim([-0.1, 1.1]); grid on;
    xlabel('Time [min]'); ylabel('LOS');
    title('LOS over Time');

    %% --- Delay over time ---
    subplot(4,3,idel);
    plot(tspan/60, delays*1e6, 'Color', colors(s,:), 'LineWidth', 1.5);
    xlabel('Time [min]'); ylabel('Delay [µs]');
    title('Propagation Delay'); grid on;
end
