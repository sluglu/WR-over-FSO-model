classdef slave_clock < wrclock
    methods
        function obj = slave_clock(f0, phi0, noiseProfile)
            obj@wrclock(f0, phi0, noiseProfile);
        end

        function obj = syntonize(obj, f_new)
            obj.noise_profile = obj.noise_profile.reset();
            obj.f = f_new;
        end
    end
end