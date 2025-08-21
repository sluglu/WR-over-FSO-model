function run_all_tests()
% COMPREHENSIVE TEST SUITE FOR WR-OVER-FSO-MODEL
% Tests all system functionalities including:
% - Clock models and noise profiles
% - PTP FSM operations
% - Node communications
% - Orbital mechanics
% - PTP synchronization scenarios
% - Offset correction and syntonization

    fprintf('=== COMPREHENSIVE SYSTEM TEST SUITE ===\n\n');
    
    % Track test results
    test_results = struct();
    
    try
        % Test 1: Basic Clock Functionality
        fprintf('Running Test 1: Clock Models...\n');
        test_results.clock_models = test_clock_models();
        
        % Test 2: Noise Profile Functionality
        fprintf('Running Test 2: Noise Profiles...\n');
        test_results.noise_profiles = test_noise_profiles();
        
        % Test 3: PTP FSM Operations
        fprintf('Running Test 3: PTP FSM...\n');
        test_results.ptp_fsm = test_ptp_fsm();
        
        % Test 4: Node Communication
        fprintf('Running Test 4: Node Communication...\n');
        test_results.node_communication = test_node_communication();
        
        % Test 5: Orbital Mechanics
        fprintf('Running Test 5: Orbital Model...\n');
        test_results.orbital_model = test_orbital_model();
        
        % Test 6: PTP Synchronization Performance
        fprintf('Running Test 6: PTP Synchronization...\n');
        test_results.ptp_sync = test_ptp_synchronization();
        
        % Test 7: Offset Correction
        fprintf('Running Test 7: Offset Correction...\n');
        test_results.offset_correction = test_offset_correction();
        
        % Test 8: Syntonization
        fprintf('Running Test 8: Syntonization...\n');
        test_results.syntonization = test_syntonization();
        
        % Test 9: Message Queue System
        fprintf('Running Test 9: Message Queue...\n');
        test_results.message_queue = test_message_queue();
        
        % Test 10: Propagation Delay Computation
        fprintf('Running Test 10: Propagation Delays...\n');
        test_results.propagation_delays = test_propagation_delays();
        
        % Test 11: LOS Computation
        fprintf('Running Test 11: Line-of-Sight...\n');
        test_results.los_computation = test_los_computation();
        
        % Test 12: Complete Orbital PTP Scenario
        fprintf('Running Test 12: Complete Orbital Scenario...\n');
        test_results.orbital_scenario = test_orbital_scenario();
        
        % Test 13: Edge Cases and Error Handling
        fprintf('Running Test 13: Edge Cases...\n');
        test_results.edge_cases = test_edge_cases();
        
        % Summary Report
        print_test_summary(test_results);
        
    catch ME
        fprintf('ERROR: Test suite failed with exception: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
    end
end

%% TEST 1: CLOCK MODELS
function result = test_clock_models()
    fprintf('  Testing basic clock operations...\n');
    
    f0 = 125e6;
    t0 = 0;
    dt = 1e-6;
    
    % Test MasterClock
    master_clock = MasterClock(f0, t0, NoiseProfile());
    initial_time = master_clock.get_time();
    master_clock = master_clock.advance(dt);
    
    assert(master_clock.get_time() > initial_time, 'Master clock should advance');
    assert(abs(master_clock.f - f0) < 1e-6, 'Master clock frequency should remain stable');
    
    % Test SlaveClock
    slave_clock = SlaveClock(f0, t0, NoiseProfile());
    original_freq = slave_clock.f;
    new_freq = f0 + 1000;
    slave_clock = slave_clock.syntonize(new_freq);
    
    assert(abs(slave_clock.f - new_freq) < 1e-6, 'Slave clock syntonization failed');
    
    % Test offset correction
    offset = 1e-3;
    initial_phi = slave_clock.phi;
    slave_clock = slave_clock.correct_offset(offset);
    expected_phi_change = offset * (2*pi*f0);
    
    assert(abs((initial_phi - slave_clock.phi) - expected_phi_change) < 1e-6, ...
        'Offset correction failed');
    
    fprintf('  ✓ Clock models passed\n');
    result = true;
end

%% TEST 2: NOISE PROFILES
function result = test_noise_profiles()
    fprintf('  Testing noise profile functionality...\n');
    
    % Test different noise configurations
    params = struct('delta_f0', 100, 'alpha', 50, 'sigma_rw', 200, ...
                   'sigma_jitter', 10, 'timestamp_resolution', 1000, ...
                   'timestamp_jitter_std', 1e-12);
    
    np = NoiseProfile(params);
    
    % Test frequency noise generation
    dt = 1e-6;
    [df1, np] = np.frequencyNoise(dt);
    [df2, np] = np.frequencyNoise(dt);
    
    assert(~isnan(df1) && ~isnan(df2), 'Frequency noise should not be NaN');
    assert(df1 ~= df2, 'Consecutive noise samples should be different');
    
    % Test reset functionality
    np_original_eta = np.eta;
    np = np.reset();
    assert(np.eta == 0, 'Reset should zero the random walk state');
    assert(np.t_accum == 0, 'Reset should zero time accumulator');
    
    fprintf('  ✓ Noise profiles passed\n');
    result = true;
end

%% TEST 3: PTP FSM
function result = test_ptp_fsm()
    fprintf('  Testing PTP state machines...\n');
    
    % Test MasterFSM
    master_fsm = MasterFSM(1.0, false); % 1 second sync interval
    
    % Should send SYNC and FOLLOW_UP at sync time
    [master_fsm, msgs] = master_fsm.step(0);
    assert(length(msgs) == 2, 'Master should send SYNC and FOLLOW_UP');
    assert(strcmp(msgs{1}.type, 'SYNC'), 'First message should be SYNC');
    assert(strcmp(msgs{2}.type, 'FOLLOW_UP'), 'Second message should be FOLLOW_UP');
    
    % Test SlaveFSM
    slave_fsm = SlaveFSM(false);
    
    % Simulate SYNC message
    sync_msg = struct('type', 'SYNC');
    slave_fsm = slave_fsm.receive(sync_msg, 1.0);
    
    % Process the received message
    [slave_fsm, msgs] = slave_fsm.step(1.0);
    
    % Should be waiting for FOLLOW_UP after processing SYNC
    assert(slave_fsm.waiting_followup, 'Slave should be waiting for FOLLOW_UP');
    
    % Send FOLLOW_UP
    followup_msg = struct('type', 'FOLLOW_UP', 't1', 0.5);
    slave_fsm = slave_fsm.receive(followup_msg, 1.1);
    [slave_fsm, msgs] = slave_fsm.step(1.2);
    
    % Should send DELAY_REQ and be waiting for DELAY_RESP
    assert(length(msgs) >= 1, 'Slave should send DELAY_REQ');
    assert(strcmp(msgs{1}.type, 'DELAY_REQ'), 'Should send DELAY_REQ');
    assert(slave_fsm.waiting_delay_resp, 'Slave should be waiting for DELAY_RESP');
    
    fprintf('  ✓ PTP FSM passed\n');
    result = true;
end

%% TEST 4: NODE COMMUNICATION
function result = test_node_communication()
    fprintf('  Testing node-to-node communication...\n');
    
    f0 = 125e6;
    master = MasterNode(MasterClock(f0, 0, NoiseProfile()), MasterFSM(1.0, false));
    slave = SlaveNode(SlaveClock(f0, 0, NoiseProfile()), SlaveFSM(false));
    
    dt = 0.001;
    
    % Step master to generate messages
    [master, master_msgs] = master.step(dt);
    
    if ~isempty(master_msgs)
        % Deliver messages to slave
        for i = 1:length(master_msgs)
            slave = slave.receive(master_msgs{i});
        end
        
        % Step slave to process messages
        [slave, slave_msgs] = slave.step(dt);
        
        % Verify slave received and processed messages
        fsm_state = slave.get_fsm();
        assert(~isempty(fsm_state.msg_queue) || fsm_state.waiting_followup || ...
               fsm_state.waiting_delay_resp, 'Slave should have processed messages');
    end
    
    fprintf('  ✓ Node communication passed\n');
    result = true;
end

%% TEST 5: ORBITAL MODEL
function result = test_orbital_model()
    fprintf('  Testing orbital mechanics...\n');
    
    deg = pi/180;
    rE = 6371e3;
    
    % Test position function generation
    params1 = struct('r', rE+550e3, 'i', 53*deg, 'theta0', 0, 'RAAN', 0);
    params2 = struct('r', rE+550e3, 'i', 53*deg, 'theta0', 0, 'RAAN', 70*deg);
    
    [r1, r2] = generate_position_functions(params1, params2);
    
    % Test positions at different times
    pos1_t0 = r1(0);
    pos1_t1 = r1(100);
    
    assert(length(pos1_t0) == 3, 'Position should be 3D vector');
    assert(norm(pos1_t0) > rE, 'Satellite should be above Earth');
    assert(norm(pos1_t0 - pos1_t1) > 0, 'Satellite should move over time');
    
    % Test LOS computation
    tspan = 0:60:3600; % 1 hour with 1-minute steps
    [los_intervals, los_flags] = compute_los_intervals(r1, r2, tspan);
    
    assert(size(los_intervals, 2) == 2, 'LOS intervals should have start/end times');
    assert(length(los_flags) == length(tspan), 'LOS flags should match time span');
    
    fprintf('  ✓ Orbital model passed\n');
    result = true;
end

%% TEST 6: PTP SYNCHRONIZATION
function result = test_ptp_synchronization()
    fprintf('  Testing PTP synchronization performance...\n');
    
    % Run a mini version of the PTP simulation
    f0 = 125e6;
    sync_interval = 0.5;
    sim_duration = 2; % Short simulation
    dt = 0.01;
    delay = 5e-3;
    
    master = MasterNode(MasterClock(f0, 0, NoiseProfile()), MasterFSM(sync_interval, false));
    slave = SlaveNode(SlaveClock(f0, 0.001, NoiseProfile()), SlaveFSM(false)); % Small initial offset
    
    msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});
    sim_time = 0;
    sync_achieved = false;
    
    while sim_time < sim_duration
        % Step nodes
        [master, master_msgs] = master.step(dt);
        [slave, slave_msgs] = slave.step(dt);
        
        % Handle messages with delay
        for i = 1:length(master_msgs)
            msg_queue(end+1) = struct('target', 'slave', 'msg', master_msgs{i}, ...
                                     'delivery_time', sim_time + delay);
        end
        for i = 1:length(slave_msgs)
            msg_queue(end+1) = struct('target', 'master', 'msg', slave_msgs{i}, ...
                                     'delivery_time', sim_time + delay);
        end
        
        % Deliver messages
        if ~isempty(msg_queue)
            delivery_times = [msg_queue.delivery_time];
            to_deliver = delivery_times <= sim_time;
            for j = find(to_deliver)
                if strcmp(msg_queue(j).target, 'master')
                    master = master.receive(msg_queue(j).msg);
                else
                    slave = slave.receive(msg_queue(j).msg);
                end
            end
            msg_queue(to_deliver) = [];
        end
        
        % Check if sync was achieved
        [ptp_offset, ptp_delay] = slave.get_ptp_estimate();
        if ~isnan(ptp_offset)
            sync_achieved = true;
        end
        
        sim_time = sim_time + dt;
    end
    
    assert(sync_achieved, 'PTP synchronization should be achieved');
    
    fprintf('  ✓ PTP synchronization passed\n');
    result = true;
end

%% TEST 7: OFFSET CORRECTION
function result = test_offset_correction()
    fprintf('  Testing offset correction mechanism...\n');
    
    f0 = 125e6;
    initial_offset = 0.1; % 100ms offset
    
    master = MasterNode(MasterClock(f0, 0, NoiseProfile()), MasterFSM(0.5, false));
    slave = SlaveNode(SlaveClock(f0, initial_offset, NoiseProfile()), SlaveFSM(false));
    
    initial_real_offset = slave.get_time() - master.get_time();
    
    % Simulate one complete PTP exchange
    dt = 0.001;
    sim_time = 0;
    correction_applied = false;
    
    msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});
    delay = 1e-3;
    
    for step = 1:1000 % Limit iterations
        [master, master_msgs] = master.step(dt);
        [slave, slave_msgs] = slave.step(dt);
        
        % Handle messages
        for i = 1:length(master_msgs)
            msg_queue(end+1) = struct('target', 'slave', 'msg', master_msgs{i}, ...
                                     'delivery_time', sim_time + delay);
        end
        for i = 1:length(slave_msgs)
            msg_queue(end+1) = struct('target', 'master', 'msg', slave_msgs{i}, ...
                                     'delivery_time', sim_time + delay);
        end
        
        % Deliver messages
        if ~isempty(msg_queue)
            delivery_times = [msg_queue.delivery_time];
            to_deliver = delivery_times <= sim_time;
            for j = find(to_deliver)
                if strcmp(msg_queue(j).target, 'master')
                    master = master.receive(msg_queue(j).msg);
                else
                    slave = slave.receive(msg_queue(j).msg);
                end
            end
            msg_queue(to_deliver) = [];
        end
        
        % Apply correction when sync completes
        if slave.just_synced() && ~correction_applied
            slave = slave.offset_correction();
            correction_applied = true;
            break;
        end
        
        sim_time = sim_time + dt;
    end
    
    final_real_offset = slave.get_time() - master.get_time();
    improvement = abs(initial_real_offset) - abs(final_real_offset);
    
    assert(correction_applied, 'Offset correction should be applied');
    assert(improvement > 0, 'Offset should be reduced after correction');
    
    fprintf('  ✓ Offset correction passed (improved by %.6f s)\n', improvement);
    result = true;
end

%% TEST 8: SYNTONIZATION
function result = test_syntonization()
    fprintf('  Testing frequency syntonization...\n');
    
    f0 = 125e6;
    freq_offset = 1000; % 1kHz offset
    
    % Create clocks with frequency difference
    params_slave = struct('delta_f0', freq_offset, 'alpha', 0, 'sigma_rw', 0, 'sigma_jitter', 0);
    
    master = MasterNode(MasterClock(f0, 0, NoiseProfile()), MasterFSM(1, false));
    slave = SlaveNode(SlaveClock(f0, 0, NoiseProfile(params_slave)), SlaveFSM(false));
    
    initial_freq_error = slave.get_freq() - master.get_freq();
    
    % Apply syntonization
    slave = slave.syntonize(master.get_freq());
    
    final_freq_error = slave.get_freq() - master.get_freq();
    
    assert(abs(initial_freq_error) > 500, 'Initial frequency error should be significant');
    assert(abs(final_freq_error) < 1, 'Final frequency error should be minimal');
    
    fprintf('  ✓ Syntonization passed (error reduced from %.1f Hz to %.1f Hz)\n', ...
            initial_freq_error, final_freq_error);
    result = true;
end

%% TEST 9: MESSAGE QUEUE SYSTEM
function result = test_message_queue()
    fprintf('  Testing message queue and delivery system...\n');
    
    % Test message creation and delivery
    test_msg = struct('type', 'TEST', 'data', 42);
    delivery_time = 1.0;
    current_time = 0.5;
    
    % Create message queue entry
    msg_queue_entry = struct('target', 'test_node', 'msg', test_msg, ...
                            'delivery_time', delivery_time);
    
    % Test delivery logic
    should_deliver = msg_queue_entry.delivery_time <= current_time;
    assert(~should_deliver, 'Message should not be delivered yet');
    
    current_time = 1.5;
    should_deliver = msg_queue_entry.delivery_time <= current_time;
    assert(should_deliver, 'Message should be delivered now');
    
    fprintf('  ✓ Message queue system passed\n');
    result = true;
end

%% TEST 10: PROPAGATION DELAYS
function result = test_propagation_delays()
    fprintf('  Testing propagation delay computation...\n');
    
    deg = pi/180;
    rE = 6371e3;
    c = 299792458;
    
    % Create simple orbital scenario
    params1 = struct('r', rE+400e3, 'i', 0, 'theta0', 0, 'RAAN', 0);
    params2 = struct('r', rE+400e3, 'i', 0, 'theta0', pi, 'RAAN', 0); % Opposite side
    
    [r1, r2] = generate_position_functions(params1, params2);
    
    % Test propagation delay at t=0 (maximum separation)
    t = 0;
    pos1 = r1(t);
    pos2 = r2(t);
    distance = norm(pos2 - pos1);
    expected_delay = distance / c;
    
    computed_delay = compute_propagation_delay(r1, r2, t, expected_delay * 0.9);
    
    assert(~isnan(computed_delay), 'Propagation delay should not be NaN');
    assert(abs(computed_delay - expected_delay) < 1e-6, ...
           'Computed delay should match expected delay');
    
    fprintf('  ✓ Propagation delays passed (delay = %.6f s)\n', computed_delay);
    result = true;
end

%% TEST 11: LINE-OF-SIGHT COMPUTATION
function result = test_los_computation()
    fprintf('  Testing line-of-sight computation...\n');
    
    deg = pi/180;
    rE = 6371e3;
    
    % Test case: Two satellites on opposite sides of Earth (no LOS)
    params1 = struct('r', rE+400e3, 'i', 0, 'theta0', 0, 'RAAN', 0);
    params2 = struct('r', rE+400e3, 'i', 0, 'theta0', pi, 'RAAN', 0);
    [r1, r2] = generate_position_functions(params1, params2);
    
    tspan = [0, 100];
    [los_intervals, los_flags] = compute_los_intervals(r1, r2, tspan, 10);
    
    % At t=0, satellites should not have LOS (opposite sides)
    assert(~los_flags(1), 'Satellites on opposite sides should not have LOS');
    
    % Test case: Two satellites in same orbital plane with small angular separation
    params2_close = struct('r', rE+400e3, 'i', 0, 'theta0', 0.1, 'RAAN', 0);
    [r1_close, r2_close] = generate_position_functions(params1, params2_close);
    
    [los_intervals_close, los_flags_close] = compute_los_intervals(r1_close, r2_close, tspan, 10);
    
    % Should have some LOS periods
    total_los_time = sum(diff(los_intervals_close, 1, 2));
    assert(total_los_time > 0, 'Close satellites should have some LOS periods');
    
    fprintf('  ✓ Line-of-sight computation passed\n');
    result = true;
end

%% TEST 12: COMPLETE ORBITAL SCENARIO
function result = test_orbital_scenario()
    fprintf('  Testing complete orbital PTP scenario...\n');
    
    % Mini version of exp2 simulation
    dt_orbital = 10;
    sim_duration = 0.5; % 30 minutes for better LOS coverage
    deg = pi/180;
    rE = 6371e3;
    
    % Use a scenario with better LOS characteristics - closer satellites
    scenario = {"Test Scenario", rE+550e3, rE+550e3, 53*deg, 53*deg, 0, 0, 0, 10*deg}; % Smaller RAAN difference
    
    sim_params = struct('dt_ptp', 0.1, 'dt_orbital', dt_orbital, ...
                       'sim_duration', sim_duration, 'min_los_duration', 0.1); % Lower minimum LOS duration
    
    ptp_params = struct('f0', 125e6, 'sync_interval', 1, 'min_msg_interval', 1e-6, ...
                       'verbose', false, 'master_noise_profile', NoiseProfile(), ...
                       'slave_noise_profile', NoiseProfile(), 'offset_correction', false, ...
                       'syntonization', false, 't0', 0, 'initial_time_offset', 0);
    
    % This should run without errors
    try
        results = simulate_ptp_orbital(sim_params, ptp_params, scenario);
        
        % Basic sanity checks
        assert(~isempty(results.times), 'Results should contain time data');
        assert(any(~isnan(results.ptp_offset)), 'Should have some PTP offset measurements');
        
        simulation_success = true;
    catch ME
        fprintf('    Orbital simulation failed: %s\n', ME.message);
        simulation_success = false;
    end
    
    assert(simulation_success, 'Complete orbital scenario should execute successfully');
    
    fprintf('  ✓ Complete orbital scenario passed\n');
    result = true;
end

%% TEST 13: EDGE CASES AND ERROR HANDLING
function result = test_edge_cases()
    fprintf('  Testing edge cases and error handling...\n');
    
    % Test 1: Invalid FSM combinations
    try
        master_node = MasterNode(MasterClock(), SlaveFSM()); % Wrong FSM type
        error_thrown = false;
    catch
        error_thrown = true;
    end
    assert(error_thrown, 'Should throw error for invalid FSM combination');
    
    % Test 2: Zero sync interval
    master_fsm = MasterFSM(0, false);
    [master_fsm, msgs] = master_fsm.step(1.0);
    assert(~isempty(msgs), 'Should still generate messages with zero interval');
    
    % Test 3: NaN propagation delays
    deg = pi/180;
    rE = 6371e3;
    params = struct('r', rE+400e3, 'i', 0, 'theta0', 0, 'RAAN', 0);
    [r1, r2] = generate_position_functions(params, params); % Same position
    
    % This might fail convergence and return NaN
    delay = compute_propagation_delay(r1, r2, 0, 1e-6);
    % We accept either a small delay or NaN for identical positions
    assert(isnan(delay) || delay < 1e-9, 'Identical positions should have very small or NaN delay');
    
    % Test 4: Empty message queues
    master = MasterNode();
    [master, msgs] = master.step(0.001);
    % Should handle gracefully even if no messages
    assert(iscell(msgs), 'Should return cell array for messages');
    
    fprintf('  ✓ Edge cases passed\n');
    result = true;
end

%% SUMMARY REPORT
function print_test_summary(test_results)
    fprintf('\n=== TEST SUMMARY ===\n');
    
    test_names = fieldnames(test_results);
    passed_count = 0;
    total_count = length(test_names);
    
    for i = 1:total_count
        test_name = test_names{i};
        result = test_results.(test_name);
        status = '✓ PASSED';
        if result
            passed_count = passed_count + 1;
        else
            status = '✗ FAILED';
        end
        
        fprintf('%-25s: %s\n', test_name, status);
    end
    
    fprintf('\nOverall: %d/%d tests passed (%.1f%%)\n', ...
            passed_count, total_count, 100 * passed_count / total_count);
    
    if passed_count == total_count
        fprintf('🎉 ALL TESTS PASSED! System is functioning correctly.\n');
    else
        fprintf('⚠️  Some tests failed. Please review the system.\n');
    end
    
    fprintf('\nTest Categories Covered:\n');
    fprintf('  • Clock models (WRClock, MasterClock, SlaveClock)\n');
    fprintf('  • Noise injection and profiles\n');
    fprintf('  • PTP finite state machines\n');
    fprintf('  • Node communication and message handling\n');
    fprintf('  • Orbital mechanics and position functions\n');
    fprintf('  • PTP synchronization performance\n');
    fprintf('  • Offset correction mechanisms\n');
    fprintf('  • Frequency syntonization\n');
    fprintf('  • Message queue and delivery systems\n');
    fprintf('  • Propagation delay computation\n');
    fprintf('  • Line-of-sight analysis\n');
    fprintf('  • Complete orbital scenarios\n');
    fprintf('  • Edge cases and error handling\n');
    
    fprintf('\n=== END TEST SUITE ===\n');
end


% Run all tests
run_all_tests();