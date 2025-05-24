classdef slave_clock < wrclock
    properties
        nominal_freq    % [Hz] - target frequency (e.g., 125 MHz for WR)
        drift_ppb       % frequency drift (static error) in ppb
        Cumulative_Jitter_std       % Cumulative phase jitter of the oscillator
        measurement_jitter_std      % jitter when timestamping
        phase_noise_ticks  % cumulative phase noise in units of ticks
        tick_callback = [];  % Function handle or empty
    end

    methods
        function obj = slave_clock(nom_freq, drift_ppb, Cumulative_Jitter_std, measurement_jitter_std)
            obj@wrclock(nom_freq);

            obj.nominal_freq = nom_freq;
            obj.drift_ppb = drift_ppb;
            obj.Cumulative_Jitter_std = Cumulative_Jitter_std;
            obj.measurement_jitter_std = measurement_jitter_std;
            obj.phase_noise_ticks = 0;

            % initial frequency drift 
            obj.frequency = nom_freq * (1 + obj.drift_ppb * 1e-9);

        end

        

        % function tick(obj, sim_dt)
        % 
        %     % Apply drift
        %     obj.frequency = obj.nominal_freq * (1 + obj.drift_ppb * 1e-9);
        % 
        %     % Execute optional callback function (for SyncE correction)
        %     if ~isempty(obj.tick_callback)
        %         obj.tick_callback(obj);  % Pass self (slave) into the callback
        %     end
        %     % Advance the clock time by 1 tick
        %     obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt;
        % end

        function tick(obj, sim_dt)
            % Advance the clock time by 1 tick, applying drift and jitter

            % Generate jitter
            % e.g., if jitter_std = 20e-12 and sim_dt = 1e-9, this = 0.02 ticks
            jitter_std_ticks = obj.Cumulative_Jitter_std / sim_dt;
            jitter_sample = randn * jitter_std_ticks;
            obj.phase_noise_ticks = obj.phase_noise_ticks + jitter_sample;
            
            %Apply drift
            obj.frequency = obj.nominal_freq * (1 + obj.drift_ppb * 1e-9);

             % Execute optional callback function (for SyncE correction)
            if ~isempty(obj.tick_callback)
                obj.tick_callback(obj);  % Pass self (slave) into the callback
            end

            obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt + obj.phase_noise_ticks;
        end

        % function apply_freq_correction(obj, correction)
        %     % Override frequency as if synchronized via SyncE
        %     obj.frequency = obj.frequency + correction;
        % end

        function apply_offset_correction(obj, offset_s)
            % Convert offset in seconds to cycles and directly apply it
            cycle_shift = offset_s * obj.frequency;
            obj.cycle_count = obj.cycle_count + cycle_shift;
        end

        function t = get_time__clean(obj)
            % Without measurement jitter
            t = obj.cycle_count / obj.nominal_freq;
        end

        function t = get_time_raw(obj)
            % For phase detector (with jitter)
            jitter = randn * obj.measurement_jitter_std;
            t = obj.cycle_count / obj.nominal_freq + jitter;
        end

        function t = get_time_tick(obj)
            % Time used for timestamps
            jitter = randn * obj.measurement_jitter_std;
            t = round(obj.cycle_count / obj.nominal_freq + jitter);
        end
    end
end