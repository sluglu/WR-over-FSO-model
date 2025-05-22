classdef slave_clock < wrclock
    methods
        function obj = slave_clock(nom_freq, drift_ppb, jitter_std)
            obj@wrclock(nom_freq, drift_ppb, jitter_std);
        end

        function syntonize(obj, new_freq)
            % Override frequency as if synchronized via SyncE
            obj.frequency = new_freq;
        end

        function apply_offset(obj, offset_s)
            % Convert offset in seconds to cycles and directly apply it
            cycle_shift = offset_s * obj.nominal_freq;
            obj.cycle_count = obj.cycle_count + cycle_shift;
        end
    end
end