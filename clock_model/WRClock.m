classdef WRClock
    properties
        f0            % Nominal frequency (Hz)
        f             % Current frequency (Hz)
        phi           % Current phase (radians)
        noise_profile NoiseProfile % NoiseProfile object
        t_accum = 0;
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
            obj.phi = 0;
            obj.f = obj.f0 + noise_profile.delta_f0;
            obj = obj.advance(t0);
        end

        function obj = advance(obj, dt)
            obj.t_accum = obj.t_accum + dt;
            [dy, obj.noise_profile] = obj.noise_profile.generatePowerLawNoise(dt);
            df = obj.noise_profile.delta_f0 + obj.noise_profile.alpha * obj.t_accum + dy * obj.f0;
            obj.f = obj.f0 + df;
            obj.phi = obj.phi + 2 * pi * obj.f * dt;
        end

        function ts = get_time(obj)
            ts = (obj.phi / (2*pi*obj.f0));
        end

        function ts = get_timestamp(obj)
            % Get the true (ideal) continuous time in seconds
            ts = obj.get_time();
    
            % Handle infinite resolution (0 means infinite precision)
            if obj.noise_profile.timestamp_resolution == 0
                return;
            end
   
            tick = 1 / obj.f;
            % Calculate quantization step in seconds
            % resolution = 1 -> quant step = 1 tick
            % resolution > 1 -> quant step = multiple ticks (coarser)
            % resolution < 1 -> quant step = fraction of tick (finer)
            quant_step = tick / obj.noise_profile.timestamp_resolution;
    
            % Quantize true time to nearest multiple of quant_step
            ts = round(ts / quant_step) * quant_step;
        end

        function obj = reset(obj, t0)
            obj.noise_profile.reset();
            obj.phi = 0;
            obj.f = obj.f0 + obj.noise_profile.delta_f0;
            if nargin > 1
                obj = obj.advance(t0);
            end
        end
    end
end
