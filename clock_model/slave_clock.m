classdef slave_clock < wrclock
    properties
        tick_callback = [];  % Function handle or empty
    end
    methods
        function obj = slave_clock(nom_freq, drift_ppb, jitter_std)
            obj@wrclock(nom_freq, drift_ppb, jitter_std);
        end

        function tick(obj, sim_dt)

            % Apply drift
            obj.frequency = obj.nominal_freq * (1 + obj.drift_ppb * 1e-9);

            % Execute optional callback function (for SyncE correction)
            if ~isempty(obj.tick_callback)
                obj.tick_callback(obj);  % Pass self (slave) into the callback
            end
            % Advance the clock time by 1 tick
            obj.cycle_count = obj.cycle_count + obj.frequency * sim_dt;
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
    end
end