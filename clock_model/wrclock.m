classdef (Abstract) wrclock
    properties
        f0            % Nominal frequency (Hz)
        phi           % Current phase (radians)
        phi0          % Initial phase (radians)
        noise_profile  % NoiseProfile object
    end

    methods
        function obj = wrclock(f0, t0, noise_profile)
            obj.f0 = f0;
            obj.phi0 = t0 * (2*pi*f0);
            obj.phi = 0;
            obj.noise_profile = noise_profile;
            obj = obj.advance(t0);
        end

        function obj = advance(obj, dt)
            [df, obj.noise_profile] = obj.noise_profile.frequencyNoise(dt);
            f = obj.f0 + df;
            obj.phi = obj.phi + 2 * pi * f * dt;
        end

        function obj = reset(obj)
            obj.phi = obj.phi0;
            obj.noise_profile = obj.noise_profile.reset();
        end
    end
end
