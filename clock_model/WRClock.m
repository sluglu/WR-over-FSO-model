classdef WRClock
    properties
        f0            % Nominal frequency (Hz)
        f             % Current frequency (Hz)
        phi           % Current phase (radians)
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
            obj.phi = 0;
            obj.f = obj.f0;
            obj = obj.advance(t0);
        end

        function obj = advance(obj, dt)
            [df, obj.noise_profile] = obj.noise_profile.frequencyNoise(dt);
            obj.f = obj.f + df;
            obj.phi = obj.phi + 2 * pi * obj.f * dt;
        end

        function ts = get_time(obj)
            ts = (obj.phi / (2*pi*obj.f0));
        end

        function ts = get_timestamp(obj)
            % Get the true (ideal) continuous time in seconds
            true_ts = obj.get_time();
    
            % Handle infinite resolution (0 means infinite precision)
            if obj.noise_profile.timestamp_resolution == 0
                % No quantization, just add jitter noise
                ts = true_ts + obj.noise_profile.timestamp_jitter_std * randn();
                return;
            end
   
            tick = 1 / obj.f;
            % Calculate quantization step in seconds
            % resolution = 1 -> quant step = 1 tick
            % resolution < 1 -> quant step = multiple ticks (coarser)
            % resolution > 1 -> quant step = fraction of tick (finer)
            quant_step = tick / obj.noise_profile.timestamp_resolution;
    
            % Quantize true time to nearest multiple of quant_step
            ts = round(true_ts / quant_step) * quant_step;
    
            % Add jitter noise (Gaussian)
            if obj.noise_profile.timestamp_jitter_std > 0
                ts = ts + obj.noise_profile.timestamp_jitter_std * randn();
            end
        end

        function obj = reset(obj)
            obj.noise_profile.reset()
            obj.f = obj.f0;
        end
    end
end
