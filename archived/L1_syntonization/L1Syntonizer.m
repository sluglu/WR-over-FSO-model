% classdef L1Syntonizer
%     methods
%         function obj = L1Syntonizer()
%         end
% 
%         function clk = syntonize(obj, f_rx, clk)
%             clk.f = f_rx;
%         end
% 
%     end
% end

classdef L1Syntonizer
    methods
        function obj = L1Syntonizer(noise_profile)
            if nargin > 0
                obj.noise_profile = noise_profile;
            else
                obj.noise_profile = NoiseProfile();
            end
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
