classdef PTPNode
    properties (Access = protected)
        clock WRClock
        fsm PTPFSM
        timestamp_resolution = 0;
        timestamp_jitter_std = 0;
    end
    
    methods
        function obj = PTPNode(clock, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.fsm = fsm;
            else
                obj.clock = WRClock();
                obj.fsm = PTPFSM();
            end
        end

        function [obj, msgs] = step(obj, dt)
            obj = obj.advance_time(dt);

            ts = obj.get_timestamp();

            % Step FSM
            [obj.fsm, msgs] = obj.fsm.step(ts);
        end

        function obj = receive(obj, msg)
            ts = obj.get_timestamp();
            obj.fsm = obj.fsm.receive(msg, ts);
        end
        
        function obj = advance_time(obj, dt)
            obj.clock = obj.clock.advance(dt);
        end

        function ts = get_time(obj)
            ts = (obj.clock.phi / (2*pi*obj.clock.f0));
        end

        function ts = get_timestamp(obj)
            % Get the true (ideal) continuous time in seconds
            true_ts = obj.get_time();
    
            % Instantaneous clock frequency and tick period
            f_inst = obj.clock.f;
            tick = 1 / f_inst;
    
            % Handle infinite resolution (0 means infinite precision)
            if obj.timestamp_resolution == 0
                % No quantization, just add jitter noise
                ts = true_ts + obj.timestamp_jitter_std * randn();
                return;
            end
    
            % Calculate quantization step in seconds
            % resolution = 1 -> quant step = 1 tick
            % resolution < 1 -> quant step = multiple ticks (coarser)
            % resolution > 1 -> quant step = fraction of tick (finer)
            quant_step = tick / obj.timestamp_resolution;
    
            % Quantize true time to nearest multiple of quant_step
            ts = round(true_ts / quant_step) * quant_step;
    
            % Add jitter noise (Gaussian)
            if obj.timestamp_jitter_std > 0
                ts = ts + obj.timestamp_jitter_std * randn();
            end
        end

        function freq = get_freq(obj)
            freq = obj.clock.f;
        end

        function phi = get_phi(obj)
            phi = obj.clock.phi;
        end

        function np = get_noise_profile(obj)
            np = obj.clock.noise_profile;
        end

        function fsm = get_fsm(obj)
            fsm = obj.fsm;
        end
        
        function clock = get_clock(obj)
            clock = obj.clock;
        end
    end
end
