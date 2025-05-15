classdef slave_clock < wrclock
    methods
        function obj = slave_clock(init_time, freq_error)
            obj@wrclock(init_time, freq_error);
        end

        function obj = adjust_phase(obj, correction)
            % Apply a time correction (e.g., from servo)
            obj.time = obj.time + correction;
        end

        function obj = adjust_frequency(obj, freq_correction)
            % Apply frequency correction (simulate SyncE / PLL)
            obj.frequency_error = obj.frequency_error + freq_correction;
        end
    end
end
