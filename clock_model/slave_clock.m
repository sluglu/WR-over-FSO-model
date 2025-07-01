classdef slave_clock < wrclock
    methods
        function obj = slave_clock(f0, phi0, noiseProfile)
            obj@wrclock(f0, phi0, noiseProfile);
        end

        function obj = syntonize(obj, f_new)
            obj.f0 = f_new;
        end
    end
end