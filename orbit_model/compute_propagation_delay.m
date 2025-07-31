function [dt, t1, d, u] = compute_propagation_delay(r1, r2, t0)
c = 299792458; % speed of light in vacuum [m/s]

residual = @(dt) norm(r2(t0 + dt) - r1(t0)) - c * dt;

% Use fzero with an initial guess, e.g., 0.01 s
dt = fzero(residual, [0, 1]);

t1 = t0 + dt;
d = c * dt;
u = (r2(t1) - r1(t0)) / norm(r2(t1) - r1(t0));
end
