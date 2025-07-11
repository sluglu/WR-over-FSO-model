clear; clc;

%% Simulation parameters

T_end = 100e-9;
dt = 1e-9;
sim_time = 0;
f0 = 125e6;
t0 = 0;

%% Instantiate nodes

% Noisy profile
params_noisy = struct(...
    'delta_f0', 50, ...
    'alpha', 100, ...
    'sigma_rw', 500, ...
    'sigma_jitter', 100e-3 ...
);
np_noisy = NoiseProfile(params_noisy);

np_ideal = NoiseProfile();

clk_slave = SlaveClock(f0, t0, np_noisy);
clk_master = MasterClock();

ts_noisy = Timestamper(np_noisy);
ts_ideal = Timestamper(np_noisy);

st_noisy = L1Syntonizer(np_noisy);
st_ideal = L1Syntonizer(np_noisy);

master = MasterNode(clk_master, ts_ideal, MasterFSM());
slave  = SlaveNode(clk_slave, ts_noisy, SlaveFSM(), st_noisy);

%% Run simulation loop
N = floor(T_end/dt) + 1;

master_cts = zeros(1, N);
slave_cts = zeros(1, N);
slave_fts = zeros(1, N);
master_fts = zeros(1, N);
master_coarse_error = zeros(1, N);
master_fine_error = zeros(1, N);
slave_coarse_error = zeros(1, N);
slave_fine_error = zeros(1, N);

for i = 1:N

    sim_time = i*dt;
    % MASTER step
    [master, msgs] = master.step(sim_time);
    master_cts(i) = master.timestamper.getCoarsePhase(master.clock);
    master_fts(i) = master.timestamper.getFinePhase(master.clock);

    % Simulate frequency received at slave (add doppler here if needed)
    rx_freq = master.clock.f + 10e7;  % example doppler shift
    
    slave = slave.syntonize(rx_freq);
    % SLAVE step
    [slave, msgs] = slave.step(sim_time);
    slave_cts(i) = slave.timestamper.getCoarsePhase(slave.clock);
    slave_fts(i) = slave.timestamper.getFinePhase(slave.clock);

    master_coarse_error(i) = master.clock.phi - master_cts(i);
    master_fine_error(i) = master.clock.phi - master_fts(i);

    slave_coarse_error(i) = master.clock.phi - slave_cts(i);
    slave_fine_error(i) = master.clock.phi - slave_fts(i);

    % Advance time
    sim_time = sim_time + dt;
end

t_vec = (0:N-1)*dt + t0;

figure('Name', 'master vs slave timestamps', 'Position', [100 100 1300 1000]);
subplot(2,2,1);
plot(t_vec, master_cts, 'b', t_vec, slave_cts, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Master','Slave'); title('master vs slave coarse timestamps');
subplot(2,2,2);
plot(t_vec, master_coarse_error, 'b', t_vec, slave_coarse_error, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Master','Slave'); title('master vs slave coarse error');

subplot(2,2,3);
plot(t_vec, master_fts, 'b ', t_vec, slave_fts, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Master','Slave'); title('master vs slave fine timestamps');
subplot(2,2,4);
plot(t_vec, master_fine_error, 'b', t_vec, slave_fine_error, 'r');
xlabel('Time'); ylabel('Phase (rad)');
legend('Master','Slave'); title('master vs slave fine error');
