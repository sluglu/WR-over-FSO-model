classdef WRClock
    properties
        f0            % Nominal frequency (Hz)
        f             % Current frequency (Hz)
        phi           % Current phase (radians)
        phi0          % Initial phase (radians)
        noise_profile NoiseProfile % NoiseProfile object
    end

    methods
        function obj = WRClock(f0, t0, noise_profile)
            if nargin > 0
                obj.f0 = f0;
                obj.noise_profile = noise_profile;
            else 
                obj.f0 = 125e6;
                obj.noise_profile = NoiseProfile();
                t0 = 0;
            end
            obj.f = obj.f0;
            obj.phi0 = t0 * (2*pi*obj.f0);
            obj.phi = obj.phi0;
            obj = obj.advance(t0);
        end

        function obj = advance(obj, dt)
            [df, obj.noise_profile] = obj.noise_profile.frequencyNoise(dt);
            obj.f = obj.f + df;
            obj.phi = obj.phi + 2 * pi * obj.f * dt;
        end

        function obj = reset(obj)
            obj.noise_profile.reset()
            obj.phi = obj.phi0;
            obj.f = obj.f0;
        end
    end
end
