classdef L1_syntonizer
    properties
        noise_profile  % NoiseProfile object
    end

    methods
        function obj = L1_syntonizer(noise_profile)
            obj.noise_profile = noise_profile;
        end

        function clk = syntonize(obj, f_rx, clk)
            % --- 2. Add noise ---
            meas_noise = obj.noise_profile.measurementNoise();
            f_distorted = f_rx + meas_noise;

            % --- 3. Update clock frequency ---
            clk = clk.syntonize(f_distorted);
        end

    end
end


