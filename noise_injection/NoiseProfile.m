% classdef NoiseProfile
%     properties
%         delta_f0     % Constant frequency offset
%         alpha        % Linear drift
%         sigma_rw     % Random walk std dev
%         sigma_jitter % High-frequency jitter std dev
%         eta = 0;        % random walk state
%         t_accum = 0;    % time accumulator (for alpha term)
%         timestamp_resolution = 0; % number of cycles of resolution for timestamps
%         timestamp_jitter_std = 0;
% 
%     end
% 
%     methods
%         function obj = NoiseProfile(params)
%             if nargin > 0
%                 obj.delta_f0     = params.delta_f0;
%                 obj.alpha        = params.alpha;
%                 obj.sigma_rw     = params.sigma_rw;
%                 obj.sigma_jitter = params.sigma_jitter;
%                 if isfield(params,'timestamp_resolution')
%                     obj.timestamp_resolution = params.timestamp_resolution;
%                     obj.timestamp_jitter_std = params.timestamp_jitter_std;
%                 end
%             else
%                 obj.delta_f0     = 0;
%                 obj.alpha        = 0;
%                 obj.sigma_rw     = 0;
%                 obj.sigma_jitter = 0;
%             end 
% 
%         end
% 
%         function [df, obj] = frequencyNoise(obj, dt)
%             % Update time
%             obj.t_accum = obj.t_accum + dt;
% 
%             % Random walk increment (delta eta)
%             d_eta = randn * obj.sigma_rw * sqrt(dt);
%             obj.eta = obj.eta + d_eta;
% 
%             % Frequency offset components
%             df = obj.delta_f0 + obj.alpha * obj.t_accum + obj.eta + randn * obj.sigma_jitter;
%         end
% 
%         function [df, obj] = compute_composite_noise(obj, dt)
%             % Update time
%             obj.t_accum = obj.t_accum + dt;
% 
%             % Random walk increment (delta eta)
%             d_eta = randn * obj.sigma_rw * sqrt(dt);
%             obj.eta = obj.eta + d_eta;
% 
%             % Frequency offset components
%             df = obj.delta_f0 + obj.alpha * obj.t_accum + obj.eta + randn * obj.sigma_jitter;
%         end
% 
%         function meas_noise = measurementNoise(obj)
%             meas_noise = randn * obj.sigma_jitter;
%         end
% 
%         function obj = reset(obj)
%             obj.t_accum = 0;
%             obj.eta = 0;
%         end
%     end
% end


% classdef NoiseProfile
%     properties
%         % Legacy parameters (for backward compatibility)
%         delta_f0     % Constant frequency offset
%         alpha        % Linear drift
%         sigma_rw     % Random walk std dev
%         sigma_jitter % High-frequency jitter std dev
%         eta = 0;        % random walk state
%         t_accum = 0;    % time accumulator (for alpha term)
%         timestamp_resolution = 0; % number of cycles of resolution for timestamps
%         timestamp_jitter_std = 0;
% 
%         % Power law noise parameters
%         use_power_law = false;  % Flag to enable power law noise
%         power_law_coeffs = [];  % [h_{-2}, h_{-1}, h_0, h_1, h_2] coefficients
%         power_law_states = [];  % Internal states for power law processes
%         sampling_rate = 1;      % Sampling rate for noise generation [Hz]
% 
%         % Filter states for power law noise generation
%         filter_states = [];
%     end
% 
%     methods
%         function obj = NoiseProfile(params)
%             if nargin > 0
%                 % Legacy parameters
%                 obj.delta_f0     = getfield_default(params, 'delta_f0', 0);
%                 obj.alpha        = getfield_default(params, 'alpha', 0);
%                 obj.sigma_rw     = getfield_default(params, 'sigma_rw', 0);
%                 obj.sigma_jitter = getfield_default(params, 'sigma_jitter', 0);
% 
%                 % Timestamp parameters
%                 if isfield(params,'timestamp_resolution')
%                     obj.timestamp_resolution = params.timestamp_resolution;
%                     obj.timestamp_jitter_std = getfield_default(params, 'timestamp_jitter_std', 0);
%                 end
% 
%                 % Power law noise parameters
%                 obj.use_power_law = getfield_default(params, 'use_power_law', false);
%                 if obj.use_power_law
%                     obj.power_law_coeffs = getfield_default(params, 'power_law_coeffs', [0 0 0 0 0]);
%                     obj.sampling_rate = getfield_default(params, 'sampling_rate', 1);
%                     obj = obj.initialize_power_law_filters();
%                 end
%             else
%                 % Default values
%                 obj.delta_f0     = 0;
%                 obj.alpha        = 0;
%                 obj.sigma_rw     = 0;
%                 obj.sigma_jitter = 0;
%             end 
%         end
% 
%         function obj = initialize_power_law_filters(obj)
%             % Initialize filter states for power law noise generation
%             % Based on Kasdin & Walter (1992) approach
% 
%             % Number of filter states needed for each noise process
%             n_states = 20; % Adjustable for accuracy vs. speed tradeoff
% 
%             obj.filter_states = struct();
% 
%             % h_{-2}: Random walk FM (f^{-2} PSD)
%             if length(obj.power_law_coeffs) >= 1 && obj.power_law_coeffs(1) > 0
%                 obj.filter_states.h_neg2 = zeros(n_states, 1);
%             end
% 
%             % h_{-1}: Flicker walk FM (f^{-1} PSD) 
%             if length(obj.power_law_coeffs) >= 2 && obj.power_law_coeffs(2) > 0
%                 obj.filter_states.h_neg1 = zeros(n_states, 1);
%             end
% 
%             % h_0: White FM (f^0 PSD) - no filter needed
%             % h_1: Flicker PM (f^1 PSD)
%             if length(obj.power_law_coeffs) >= 4 && obj.power_law_coeffs(4) > 0
%                 obj.filter_states.h_1 = zeros(n_states, 1);
%             end
% 
%             % h_2: White PM (f^2 PSD) - no filter needed
%         end
% 
%         function [df, obj] = frequencyNoise(obj, dt)
%             % Update time
%             obj.t_accum = obj.t_accum + dt;
% 
%             if obj.use_power_law
%                 [df, obj] = obj.generatePowerLawNoise(dt);
%             else
%                 % Legacy noise model
%                 % Random walk increment (delta eta)
%                 d_eta = randn * obj.sigma_rw * sqrt(dt);
%                 obj.eta = obj.eta + d_eta;
% 
%                 % Frequency offset components
%                 df = obj.delta_f0 + obj.alpha * obj.t_accum + obj.eta + randn * obj.sigma_jitter;
%             end
%         end
% 
%         function [df, obj] = generatePowerLawNoise(obj, dt)
%             % Generate power law noise based on h coefficients
%             % Following IEEE Std 1139-2008 definitions
% 
%             df = 0;
%             tau = dt; % Measurement interval
% 
%             % Ensure tau is not zero or negative
%             if tau <= 0
%                 df = 0;
%                 return;
%             end
% 
%             % h_{-2}: Random Walk Frequency Modulation (RWFM)
%             if obj.power_law_coeffs(1) > 0 && isfield(obj.filter_states, 'h_neg2') && ~isempty(obj.filter_states.h_neg2)
%                 % Random walk FM - integrated white noise
%                 white_noise = randn * sqrt(obj.power_law_coeffs(1) * tau);
%                 obj.filter_states.h_neg2(2:end) = obj.filter_states.h_neg2(1:end-1);
%                 obj.filter_states.h_neg2(1) = obj.filter_states.h_neg2(1) + white_noise;
%                 rwfm_contribution = obj.filter_states.h_neg2(1);
%                 df = df + rwfm_contribution;
%             end
% 
%             % h_{-1}: Flicker Walk Frequency Modulation (FWFM)  
%             if obj.power_law_coeffs(2) > 0 && isfield(obj.filter_states, 'h_neg1') && ~isempty(obj.filter_states.h_neg1)
%                 % Flicker walk FM - use first-order approximation
%                 white_noise = randn * sqrt(obj.power_law_coeffs(2) * 2 * log(2));
%                 obj.filter_states.h_neg1(2:end) = obj.filter_states.h_neg1(1:end-1);
%                 obj.filter_states.h_neg1(1) = white_noise;
% 
%                 % Simple moving average with 1/sqrt(k) weights
%                 n_terms = min(10, length(obj.filter_states.h_neg1)); % Limit for stability
%                 weights = 1 ./ sqrt(1:n_terms);
%                 fwfm_contribution = sum(obj.filter_states.h_neg1(1:n_terms) .* weights') / sqrt(tau);
%                 df = df + fwfm_contribution;
%             end
% 
%             % h_0: White Frequency Modulation (WFM)
%             if obj.power_law_coeffs(3) > 0
%                 wfm_contribution = randn * sqrt(obj.power_law_coeffs(3) / tau);
%                 df = df + wfm_contribution;
%             end
% 
%             % h_1: Flicker Phase Modulation (FPM) 
%             if obj.power_law_coeffs(4) > 0 && isfield(obj.filter_states, 'h_1') && ~isempty(obj.filter_states.h_1)
%                 % Flicker PM - differentiating flicker phase noise
%                 white_noise = randn * sqrt(obj.power_law_coeffs(4) * 2 * log(2) / tau);
%                 obj.filter_states.h_1(2:end) = obj.filter_states.h_1(1:end-1);
%                 obj.filter_states.h_1(1) = white_noise;
% 
%                 % Weighted sum for flicker process, then differentiate
%                 n_terms = min(5, length(obj.filter_states.h_1));
%                 weights = 1 ./ sqrt(1:n_terms);
%                 fpm_contribution = sum(obj.filter_states.h_1(1:n_terms) .* weights');
%                 df = df + fpm_contribution;
%             end
% 
%             % h_2: White Phase Modulation (WPM)
%             if obj.power_law_coeffs(5) > 0
%                 % White PM - second derivative of white phase
%                 wpm_contribution = randn * sqrt(3 * obj.power_law_coeffs(5) / tau^3);
%                 df = df + wpm_contribution;
%             end
% 
%             % Sanity check - ensure df is finite
%             if ~isfinite(df)
%                 warning('Non-finite frequency noise detected, setting to zero');
%                 df = 0;
%             end
%         end
% 
%         function meas_noise = measurementNoise(obj)
%             if obj.use_power_law
%                 % For power law noise, measurement noise is typically included in h_2 term
%                 meas_noise = 0;
%             else
%                 meas_noise = randn * obj.timestamp_jitter_std;
%             end
%         end
% 
%         function obj = reset(obj)
%             obj.t_accum = 0;
%             obj.eta = 0;
% 
%             if obj.use_power_law
%                 obj = obj.initialize_power_law_filters();
%             end
%         end
% 
%         function obj = set_power_law_params(obj, h_coeffs, sampling_rate)
%             % Convenience method to set power law parameters
%             % h_coeffs = [h_{-2}, h_{-1}, h_0, h_1, h_2] in units of rad^2/Hz^α
%             % sampling_rate in Hz
% 
%             obj.use_power_law = true;
%             obj.power_law_coeffs = h_coeffs;
%             obj.sampling_rate = sampling_rate;
%             obj = obj.initialize_power_law_filters();
%         end
% 
%         function sigma_y = allan_deviation_estimate(obj, tau)
%             % Estimate Allan deviation for given averaging time tau
%             % Based on power law coefficients
% 
%             if ~obj.use_power_law
%                 warning('Allan deviation estimation requires power law noise model');
%                 sigma_y = NaN;
%                 return;
%             end
% 
%             % IEEE Std 1139-2008 formulas
%             sigma_y_squared = 0;
% 
%             % Each noise type contribution to Allan variance
%             if obj.power_law_coeffs(1) ~= 0  % h_{-2}
%                 sigma_y_squared = sigma_y_squared + (2 * pi^2 * obj.power_law_coeffs(1) * tau) / 6;
%             end
% 
%             if obj.power_law_coeffs(2) ~= 0  % h_{-1}  
%                 sigma_y_squared = sigma_y_squared + (2 * pi^2 * obj.power_law_coeffs(2) * log(2)) / tau;
%             end
% 
%             if obj.power_law_coeffs(3) ~= 0  % h_0
%                 sigma_y_squared = sigma_y_squared + obj.power_law_coeffs(3) / (2 * tau);
%             end
% 
%             if obj.power_law_coeffs(4) ~= 0  % h_1
%                 sigma_y_squared = sigma_y_squared + obj.power_law_coeffs(4) / (2 * pi^2 * tau^3);
%             end
% 
%             if obj.power_law_coeffs(5) ~= 0  % h_2
%                 sigma_y_squared = sigma_y_squared + (3 * obj.power_law_coeffs(5)) / (4 * pi^2 * tau^5);
%             end
% 
%             sigma_y = sqrt(sigma_y_squared);
%         end
%     end
% end
% 
% % Helper function for backward compatibility
% function val = getfield_default(struct, field, default)
%     if isfield(struct, field)
%         val = struct.(field);
%     else
%         val = default;
%     end
% end

classdef NoiseProfile
    properties
        delta_f0;     % Constant frequency offset [Hz]
        alpha;        % Linear drift [Hz/s]
        timestamp_resolution; % number of cycles of resolution for timestamps
        power_law_coeffs;  % [h_{-2}, h_{-1}, h_0, h_1, h_2] for the Power Spectral Density of fractional frequency noise, S_y(f).
        filter_states; % Filter states for power law noise generation
        t_accum = 0;
    end

    methods
        function obj = NoiseProfile(params)
            if nargin == 0
                params = struct();
            end
            obj.delta_f0 = getfield_default(params, 'delta_f0', 0);
            obj.alpha = getfield_default(params, 'alpha', 0);
            obj.timestamp_resolution = getfield_default(params, 'timestamp_resolution', 0);
            obj.power_law_coeffs = getfield_default(params, 'power_law_coeffs', [0 0 0 0 0]);
            obj = obj.initialize_power_law_filters();
        end

        function obj = initialize_power_law_filters(obj)
            % Initialize filter states for power law noise generation
            % Based on Kasdin & Walter (1992) approach
            
            % Number of filter states needed for each noise process
            n_states = 20; % Adjustable for accuracy vs. speed tradeoff
            
            obj.filter_states = struct();
            
            % h_{-2}: Random walk FM (f^{-2} PSD)
            if length(obj.power_law_coeffs) >= 1 && obj.power_law_coeffs(1) > 0
                obj.filter_states.h_neg2 = zeros(n_states, 1);
            end
            
            % h_{-1}: Flicker walk FM (f^{-1} PSD) 
            if length(obj.power_law_coeffs) >= 2 && obj.power_law_coeffs(2) > 0
                obj.filter_states.h_neg1 = zeros(n_states, 1);
            end
            
            % h_0: White FM (f^0 PSD) - no filter needed
            % h_1: Flicker PM (f^1 PSD)
            if length(obj.power_law_coeffs) >= 4 && obj.power_law_coeffs(4) > 0
                obj.filter_states.h_1 = zeros(n_states, 1);
            end
            
            % h_2: White PM (f^2 PSD) - no filter needed
        end
        
        function [dy, obj] = generatePowerLawNoise(obj, dt)
            % Generate power law noise based on h coefficients
            % Following IEEE Std 1139-2008 definitions
            
            dy = 0;
            tau = dt; % Measurement interval
            
            % Ensure tau is not zero or negative
            if tau <= 0
                dy = 0;
                return;
            end
            
            % h_{-2}: Random Walk Frequency Modulation (RWFM)
            if obj.power_law_coeffs(1) > 0 && isfield(obj.filter_states, 'h_neg2') && ~isempty(obj.filter_states.h_neg2)
                % Random walk FM - integrated white noise
                white_noise = randn * sqrt(obj.power_law_coeffs(1) * tau);
                obj.filter_states.h_neg2(2:end) = obj.filter_states.h_neg2(1:end-1);
                obj.filter_states.h_neg2(1) = obj.filter_states.h_neg2(1) + white_noise;
                rwfm_contribution = obj.filter_states.h_neg2(1);
                dy = dy + rwfm_contribution;
            end
            
            % h_{-1}: Flicker Walk Frequency Modulation (FWFM)  
            if obj.power_law_coeffs(2) > 0 && isfield(obj.filter_states, 'h_neg1') && ~isempty(obj.filter_states.h_neg1)
                % Flicker walk FM - use first-order approximation
                white_noise = randn * sqrt(obj.power_law_coeffs(2) * 2 * log(2));
                obj.filter_states.h_neg1(2:end) = obj.filter_states.h_neg1(1:end-1);
                obj.filter_states.h_neg1(1) = white_noise;
                
                % Simple moving average with 1/sqrt(k) weights
                n_terms = min(10, length(obj.filter_states.h_neg1)); % Limit for stability
                weights = 1 ./ sqrt(1:n_terms);
                fwfm_contribution = sum(obj.filter_states.h_neg1(1:n_terms) .* weights') / sqrt(tau);
                dy = dy + fwfm_contribution;
            end
            
            % h_0: White Frequency Modulation (WFM)
            if obj.power_law_coeffs(3) > 0
                wfm_contribution = randn * sqrt(obj.power_law_coeffs(3) / tau);
                dy = dy + wfm_contribution;
            end
            
            % h_1: Flicker Phase Modulation (FPM) 
            if obj.power_law_coeffs(4) > 0 && isfield(obj.filter_states, 'h_1') && ~isempty(obj.filter_states.h_1)
                % Flicker PM - differentiating flicker phase noise
                white_noise = randn * sqrt(obj.power_law_coeffs(4) * 2 * log(2) / tau);
                obj.filter_states.h_1(2:end) = obj.filter_states.h_1(1:end-1);
                obj.filter_states.h_1(1) = white_noise;
                
                % Weighted sum for flicker process, then differentiate
                n_terms = min(5, length(obj.filter_states.h_1));
                weights = 1 ./ sqrt(1:n_terms);
                fpm_contribution = sum(obj.filter_states.h_1(1:n_terms) .* weights');
                dy = dy + fpm_contribution;
            end
            
            % h_2: White Phase Modulation (WPM)
            if obj.power_law_coeffs(5) > 0
                % White PM - second derivative of white phase
                wpm_contribution = randn * sqrt(3 * obj.power_law_coeffs(5) / tau^3);
                dy = dy + wpm_contribution;
            end
            
            % Sanity check - ensure df is finite
            if ~isfinite(dy)
                warning('Non-finite frequency noise detected, setting to zero');
                dy = 0;
            end
        end

        function obj = reset(obj)
            obj = obj.initialize_power_law_filters();
        end
        
        function obj = set_power_law_params(obj, h_coeffs)
            % Convenience method to set power law parameters
            % h_coeffs = [h_{-2}, h_{-1}, h_0, h_1, h_2] for the Power Spectral Density
            % of fractional frequency noise, S_y(f).
            
            obj.power_law_coeffs = h_coeffs;
            obj = obj.initialize_power_law_filters();
        end

        function sigma_y = allan_deviation_estimate(obj, tau)
            % Estimate Allan deviation for a given averaging time tau.
            % Based on the standard formulas from IEEE Std 1139-2008.
            % Assumes h_coeffs define the PSD of fractional frequency noise, S_y(f).

            sigma_y_squared = 0;
            h = obj.power_law_coeffs; % Use a shorter name for clarity

            % h_{-2}: Random Walk FM
            if h(1) ~= 0
                sigma_y_squared = sigma_y_squared + ( (2*pi)^2 * h(1) * tau / 6 );
            end

            % h_{-1}: Flicker FM
            if h(2) ~= 0
                sigma_y_squared = sigma_y_squared + ( h(2) * 2 * log(2) );
            end

            % h_0: White FM
            if h(3) ~= 0
                sigma_y_squared = sigma_y_squared + ( h(3) / (2 * tau) );
            end

            % h_1: Flicker PM
            if h(4) ~= 0
                % This formula requires the system's measurement bandwidth, f_h.
                % We will assume a common simplification.
                % The exact formula is complex: h(4) * (1.038 + 3*log(2*pi*f_h*tau)) / (4*pi^2*tau^2)
                % Let's use the more common simplified form if f_h is not available.
                % For now, we will use the dominant term for simplicity.
                % NOTE: This is an approximation.
                sigma_y_squared = sigma_y_squared + ( h(4) / (2 * (pi * tau)^2) * (1.038 + 3*log(2*pi*1e6*tau)) ); % Assumes 1MHz bandwidth f_h
            end

            % h_2: White PM
            if h(5) ~= 0
                sigma_y_squared = sigma_y_squared + ( 3 * h(5) / ( (2*pi*tau)^2 ) );
            end

            sigma_y = sqrt(sigma_y_squared);
        end
    end
end

