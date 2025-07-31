function los_intervals = compute_los_intervals(r1, r2, t_range, dt)
% t_range: [t_start, t_end], dt: timestep
RE = 6371e3; % Earth radius in meters
times = t_range(1):dt:t_range(2);
los_flags = false(size(times));

for k = 1:length(times)
    t = times(k);
    p1 = r1(t);
    p2 = r2(t);
    d_vec = p2 - p1;

    dmin = norm(cross(d_vec, p1)) / norm(d_vec);
    los_flags(k) = (dmin > RE);
end

% Detect continuous LOS intervals
los_intervals = [];
in_los = false;
for k = 1:length(times)
    if los_flags(k) && ~in_los
        t_start = times(k);
        in_los = true;
    elseif ~los_flags(k) && in_los
        t_end = times(k-1);
        los_intervals = [los_intervals; t_start, t_end];
        in_los = false;
    end
end

% If still in LOS at the end
if in_los
    los_intervals = [los_intervals; t_start, times(end)];
end
end
