classdef master_clock < wrclock
    methods
        function obj = master_clock(f0, phi0, noiseProfile)
            obj@wrclock(f0, phi0, noiseProfile);
        end
    end
end