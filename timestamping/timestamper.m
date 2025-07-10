classdef Timestamper
    properties
        noise_profile NoiseProfile % NoiseProfile object
    end

    methods
        function obj = Timestamper(noise_profile)
            if nargin > 0
                obj.noise_profile = noise_profile;
            else
                obj.noise_profile = NoiseProfile();
            end
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


