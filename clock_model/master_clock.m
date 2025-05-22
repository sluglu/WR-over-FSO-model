classdef master_clock < wrclock
    methods
        function obj = master_clock(nom_freq)
            obj@wrclock(nom_freq, 0, 0);
        end
    end
end