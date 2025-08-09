classdef PTPNode
    properties (Access = protected)
        clock WRClock
        fsm PTPFSM
    end
    
    methods
        function obj = PTPNode(clock, fsm, varargin)
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
            ts = obj.clock.get_time();
        end

        function ts = get_timestamp(obj)
            ts = obj.clock.get_timestamp();
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
