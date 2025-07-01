classdef (Abstract) wrclock
    properties
        f0            % Nominal frequency (Hz)
        phi           % Current phase (radians)
        phi0          % Initial phase (radians)
        noise_profile  % NoiseProfile object
    end

    methods
        function obj = wrclock(f0, phi0, noise_profile)
            obj.f0 = f0;
            obj.phi0 = phi0;
            obj.phi = phi0;
            obj.noise_profile = noise_profile;
        end

        function obj = advance(obj, dt)
            [df, obj.noise_profile] = obj.noise_profile.frequencyNoise(dt);
            f = obj.f0 + df;
            obj.phi = obj.phi + 2 * pi * f * dt;
        end

        function cycles = getCoarsePhase(obj)
            cycles = floor(obj.phi);
        end

        function phase = getFinePhase(obj)
            phase = obj.phi;
        end

        function obj = reset(obj)
            obj.phi = obj.phi0;
            obj.noise_profile = obj.noise_profile.reset();
        end
    end
end
