% classdef Timestamper
%     properties
%         noise_profile NoiseProfile % NoiseProfile object
%     end
% 
%     methods
%         function obj = Timestamper(noise_profile)
%             if nargin > 0
%                 obj.noise_profile = noise_profile;
%             else
%                 obj.noise_profile = NoiseProfile();
%             end
%         end
% 
%         function phase = getCoarsePhase(obj, clk) 
%             phase = floor(clk.phi);
%         end
% 
%         function phase = getFinePhase(obj, clk)
%             meas_phi = clk.phi + obj.noise_profile.measurementNoise();
%             delta = meas_phi - getCoarsePhase(obj, clk);
%             phase = getCoarsePhase(obj, clk) + delta;
%         end
% 
%         function [cts, fts] = getTimestamp(obj, clk)
%             cts = obj.getCoarsePhase(clk) / (2*pi*clk.f0);
%             %cts = obj.getFinePhase(clk) / (2*pi*clk.f0);
%             fts = obj.getFinePhase(clk) / (2*pi*clk.f0);
%         end
% 
% 
%     end
% end


classdef Timestamper
    properties
        measurement_noise 
        phy_clock_offset     % Simulates PHY clock domain offset
        domain_crossing_jitter % Clock domain crossing uncertainty
        ddmtd_resolution     % DDMTD measurement resolution
    end

    methods
        function obj = Timestamper(measurement_noise, ...
                                                phy_clock_offset, ...
                                                domain_crossing_jitter, ...
                                                ddmtd_resolution)
            if nargin > 0
                obj.measurement_noise = measurement_noise;
                obj.phy_clock_offset = phy_clock_offset;
                obj.domain_crossing_jitter = domain_crossing_jitter;
                obj.ddmtd_resolution = ddmtd_resolution;
            else
                obj.measurement_noise = 0; %TODO : find typical value
                obj.domain_crossing_jitter = 0;  % ±4ns domain crossing uncertainty
                obj.ddmtd_resolution = 0;      % 10ps DDMTD resolution
                obj.phy_clock_offset = randn * 0; % Random PHY offset ~100ps
            end

        end

        function timestamp = getTxTimestamp(obj, clk)
            % TX timestamps in White Rabbit are precise (local clock domain)
            % No domain crossing issues for transmission
            timestamp = clk.phi / (2*pi*clk.f0) + obj.measurement_noise;
        end

        function [basic_ts, enhanced_ts] = getRxTimestamp(obj, clk)
            % RX timestamps suffer from clock domain crossing

            % 1. Basic timestamp (SFD detection in PCS)
            % This has domain crossing uncertainty
            domain_crossing_error = (rand - 0.5) * obj.domain_crossing_jitter;
            basic_phase = clk.phi + obj.phy_clock_offset * (2*pi*clk.f0) + ...
                         domain_crossing_error * (2*pi*clk.f0);

            % Quantize to clock cycle (± 1 LSB error)
            clock_period = 1/clk.f0;
            quantized_phase = floor(basic_phase / (2*pi)) * (2*pi);
            basic_ts = quantized_phase / (2*pi*clk.f0);

            % 2. DDMTD Enhancement Process
            % Measures precise phase difference and corrects timestamp
            ddmtd_noise = randn * obj.ddmtd_resolution;
            true_phase = clk.phi / (2*pi*clk.f0);

            % DDMTD measures phase difference between domains
            phase_correction = true_phase - basic_ts + ddmtd_noise;

            % Enhanced timestamp (t2p, t4p in WR spec)
            enhanced_ts = basic_ts + phase_correction;
        end

        function [cts, fts] = getTimestamp(obj, clk)
            % For compatibility - returns TX timestamp for both
            % (This method used by step() functions)
            cts = obj.getTxTimestamp(clk);
            [basic_ts, fts] = obj.getRxTimestamp(clk);
        end
    end
end

classdef CorrectedWRTimestamper
    properties
        noise_profile NoiseProfile
        clock_period    % 125MHz = 8ns period
        ddmtd_resolution % DDMTD measurement resolution (~10ps)
        local_phase_offset % Local oscillator phase offset
    end

    methods
        function obj = CorrectedWRTimestamper(noise_profile)
            if nargin > 0
                obj.noise_profile = noise_profile;
            else
                obj.noise_profile = NoiseProfile();
            end
            
            obj.clock_period = 8e-9;        % 125MHz clock period
            obj.ddmtd_resolution = 10e-12;  % 10ps DDMTD resolution
            obj.local_phase_offset = rand * obj.clock_period; % Random local phase
        end

        function [basic_ts, enhanced_ts] = getBasicTimestamp(obj, clk)
            % ALL White Rabbit timestamps start as "basic timestamps"
            % with ±1 LSB error (8ns) due to clock quantization
            
            true_time = clk.phi / (2*pi*clk.f0);
            
            % SFD detection in PCS - quantized to clock edges
            % This creates the ±8ns uncertainty mentioned in the spec
            quantized_cycles = round(true_time / obj.clock_period);
            basic_ts = quantized_cycles * obj.clock_period;
            
            % Add measurement noise
            measurement_noise = obj.noise_profile.measurementNoise();
            basic_ts = basic_ts + measurement_noise;
            
            % For now, enhanced_ts is the same - will be overridden
            enhanced_ts = basic_ts;
        end

        function enhanced_ts = enhanceTxTimestamp(obj, basic_ts, clk)
            % TX timestamp enhancement using LOCAL phase information
            % Since TX is in local clock domain, we have precise phase info
            
            true_time = clk.phi / (2*pi*clk.f0);
            
            % Calculate fractional part within clock cycle
            fractional_part = mod(true_time, obj.clock_period);
            
            % Add DDMTD-style noise to the enhancement
            enhancement_noise = randn * obj.ddmtd_resolution;
            
            % Enhanced timestamp = basic + fractional correction
            enhanced_ts = basic_ts + fractional_part + enhancement_noise;
        end

        function enhanced_ts = enhanceRxTimestamp(obj, basic_ts, clk)
            % RX timestamp enhancement using DDMTD cross-domain measurement
            % This simulates the "Fine Delay Measurement" process
            
            true_time = clk.phi / (2*pi*clk.f0);
            
            % DDMTD measures phase difference between local and remote clocks
            % In simulation, we can calculate this directly
            phase_error = true_time - basic_ts;
            
            % Add DDMTD measurement noise and resolution limits
            ddmtd_noise = randn * obj.ddmtd_resolution;
            quantized_correction = round(phase_error / obj.ddmtd_resolution) * obj.ddmtd_resolution;
            
            % Enhanced timestamp using DDMTD correction
            enhanced_ts = basic_ts + quantized_correction + ddmtd_noise;
        end

        function [basic_ts, enhanced_ts] = getTxTimestamp(obj, clk)
            % TX timestamping process
            [basic_ts, ~] = obj.getBasicTimestamp(clk);
            enhanced_ts = obj.enhanceTxTimestamp(basic_ts, clk);
        end

        function [basic_ts, enhanced_ts] = getRxTimestamp(obj, clk)
            % RX timestamping process  
            [basic_ts, ~] = obj.getBasicTimestamp(clk);
            enhanced_ts = obj.enhanceRxTimestamp(basic_ts, clk);
        end

        function [cts, fts] = getTimestamp(obj, clk)
            % For backward compatibility - returns enhanced TX timestamp
            [basic_ts, enhanced_ts] = obj.getTxTimestamp(clk);
            cts = basic_ts;     % Basic (coarse) timestamp
            fts = enhanced_ts;  % Enhanced (fine) timestamp
        end
    end
end

