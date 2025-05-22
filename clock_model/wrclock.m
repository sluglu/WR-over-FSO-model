classdef wrclock < handle
    properties
        frequency       % [Hz] - actual oscillator frequency, updated by syntonization
        nominal_freq    % [Hz] - target frequency (e.g., 125 MHz for WR)
        drift_ppb       % frequency drift (static error) in ppb
        jitter_std      % jitter (random) in seconds
        cycle_count = 0 % double clock cycles elapsed
    end

    methods
        function obj = wrclock(nom_freq, drift_ppb, jitter_std)
            obj.nominal_freq = nom_freq;
            obj.drift_ppb = drift_ppb;
            obj.jitter_std = jitter_std;

            % initial frequency drift 
            obj.frequency = nom_freq * (1 + obj.drift_ppb * 1e-9);
        end

        function tick(obj, sim_dt)
            obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt;
            obj.frequency = obj.nominal_freq * (1 + obj.drift_ppb * 1e-9);
        end

        function t = get_time(obj)
            % Time as measured by clock cycles
            jitter = randn * obj.jitter_std;
            t = round(obj.cycle_count) / obj.nominal_freq + jitter;
        end

        function t = get_time_raw(obj)
            % For internal debugging and phase detector (DDMTD)
            jitter = randn * obj.jitter_std;
            t = obj.cycle_count / obj.nominal_freq + jitter;
        end

        function reset(obj)
            obj.cycle_count = 0;
        end
    end
end