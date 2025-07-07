classdef timestamper
    properties
        noise_profile  % NoiseProfile object
    end

    methods
        function obj = timestamper(noise_profile)
            obj.noise_profile = noise_profile;
        end

        function phase = getCoarsePhase(obj, clk) 
            phase = floor(clk.phi);
        end

        function phase = getFinePhase(obj, clk)
            meas_phi = clk.phi + obj.noise_profile.measurementNoise();
            delta = meas_phi - getCoarsePhase(obj, clk);
            phase = getCoarsePhase(obj, clk) + delta;
        end
    end
end


