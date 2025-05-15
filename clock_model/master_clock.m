classdef master_clock < wrclock
    methods
        function obj = master_clock(init_time)
            obj@wrclock(init_time, 0);  % Inherit, no frequency error
        end
    end
end