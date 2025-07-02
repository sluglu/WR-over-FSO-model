classdef timestamper
    properties
        noise_profile_meas  % NoiseProfile object
    end

    methods
        function obj = timestamper(noise_profile)
            obj.noise_profile_meas = noise_profile;
        end

        function phase = getCoarsePhase(obj, clk)
            T_clk = 1/clk.f0;
            phase = floor(clk.phi / T_clk) * T_clk;
        end

        function phase = getFinePhase(obj, clk)
            meas_phi = clk.phi + obj.noise_profile_meas.measurementNoise();
            delta = meas_phi - getCoarsePhase(obj, clk);
            phase = getCoarsePhase(obj, clk) + delta;
        end
    end
end


