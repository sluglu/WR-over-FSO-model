classdef wrclock < handle
    properties
        frequency       % [Hz] - actual oscillator frequency, updated by syntonization
        cycle_count     % double clock cycles elapsed
    end

    methods
        function obj = wrclock(nom_freq)

            obj.cycle_count = 0;
            obj.frequency = nom_freq;
            % obj.nominal_freq = nom_freq;
            % obj.drift_ppb = drift_ppb;
            % obj.jitter_std = jitter_std;
            % phase_noise_ticks = 0;
            % 
            % jitter_std_ticks = obj.jitter_std / obj.sim_dt;  % e.g., if jitter_std = 20e-12 and sim_dt = 1e-9, this = 0.02 ticks
            % 
            % % initial frequency drift 
            % obj.frequency = nom_freq * (1 + obj.drift_ppb * 1e-9);
        end

        % function tick(obj, sim_dt)
        %     % Advance the clock time by 1 tick, applying drift and jitter
        % 
        %     % Generate jitter
        %     jitter_sample = randn * obj.jitter_std_ticks;
        %     obj.phase_noise_ticks = obj.phase_noise_ticks + jitter_sample;
        % 
        %     %Apply drift
        %     obj.frequency = obj.nominal_freq * (1 + obj.drift_ppb * 1e-9);
        % 
        %     obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt;
        % end


        function tick(obj, sim_dt)
            obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt;
        end


        function t = get_time_raw(obj)
            t = obj.cycle_count / obj.frequency;
        end

        function t = get_time_tick(obj)
            % Time used for timestamps
            t = round(obj.cycle_count / obj.frequency);
        end

        function reset(obj)
            obj.cycle_count = 0;
        end
    end
end
