classdef wrclock
    %wrclock Virtual wrclock for White Rabbit simulation
    properties
        time           % Current time of the wrclock (seconds)
        Tref           % Nominal tick period (seconds) - e.g., 8e-9 s
        frequency_error % Relative frequency error (e.g., 50e-6 for 50 ppm)
    end

    methods
        function obj = wrclock(init_time, frequency_error)
            obj.time = init_time;
            obj.frequency_error = frequency_error;
        end

        function obj = wait(obj, delay_s)
        %WAIT Advance the clock by a real-world delay
            obj.time = obj.time + delay_s * (1 + obj.frequency_error);
        end

        function t = get_time(obj)
            % Read current time
            t = obj.time;
        end

        function t = get_frequency_error(obj)
            % Read current time
            t = obj.frequency_error;
        end
    end
end
