classdef noise_profile
    properties
        delta_f0     % Constant frequency offset
        alpha        % Linear drift
        sigma_rw     % Random walk std dev
        sigma_jitter % High-frequency jitter std dev
        t_accum      % Accumulated time (for drift)
        eta          % Random walk state

    end

    methods
        function obj = noise_profile(params)
            obj.delta_f0     = params.delta_f0;
            obj.alpha        = params.alpha;
            obj.sigma_rw     = params.sigma_rw;
            obj.sigma_jitter = params.sigma_jitter;
            obj.t_accum      = 0;
            obj.eta          = 0;
        end

        function [df_total, obj] = frequencyNoise(obj, dt)
            obj.t_accum = obj.t_accum + dt;
            w = randn * obj.sigma_rw * sqrt(dt);
            obj.eta = obj.eta + w;

            jitter = randn * obj.sigma_jitter;
            df_total = obj.delta_f0 + obj.alpha * obj.t_accum + obj.eta + jitter;
        end

        function obj = reset(obj)
            obj.eta = 0;
            obj.t_accum = 0; 
        end
    end
end
