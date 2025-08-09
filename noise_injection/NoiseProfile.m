classdef NoiseProfile
    properties
        delta_f0     % Constant frequency offset
        alpha        % Linear drift
        sigma_rw     % Random walk std dev
        sigma_jitter % High-frequency jitter std dev
        eta = 0;        % random walk state
        t_accum = 0;    % time accumulator (for alpha term)
        timestamp_resolution = 0; % number of cycles of resolution for timestamps
        timestamp_jitter_std = 0;

    end

    methods
        function obj = NoiseProfile(params)
            if nargin > 0
                obj.delta_f0     = params.delta_f0;
                obj.alpha        = params.alpha;
                obj.sigma_rw     = params.sigma_rw;
                obj.sigma_jitter = params.sigma_jitter;
                if isfield(params,'timestamp_resolution')
                    obj.timestamp_resolution = params.timestamp_resolution;
                    obj.timestamp_jitter_std = params.timestamp_jitter_std;
                end
            else
                obj.delta_f0     = 0;
                obj.alpha        = 0;
                obj.sigma_rw     = 0;
                obj.sigma_jitter = 0;
            end 

        end

        function [df, obj] = frequencyNoise(obj, dt)
            % Update time
            obj.t_accum = obj.t_accum + dt;

            % Random walk increment (delta eta)
            d_eta = randn * obj.sigma_rw * sqrt(dt);
            obj.eta = obj.eta + d_eta;

            % Frequency offset components
            df = obj.delta_f0 + obj.alpha * obj.t_accum + obj.eta + randn * obj.sigma_jitter;
        end

        function meas_noise = measurementNoise(obj)
            meas_noise = randn * obj.sigma_jitter;
        end

        function obj = reset(obj)
            obj.t_accum = 0;
            obj.eta = 0;
        end
    end
end
