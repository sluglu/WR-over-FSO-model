classdef SlaveNode
    properties
        clock SlaveClock
        fsm SlaveFSM
    end

    methods
        function obj = SlaveNode(clock, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.fsm = fsm;
            else
                obj.clock = SlaveClock();
                obj.fsm = SlaveFSM();
            end
        end

        function [obj, msgs] = step(obj, sim_time)
            % Advance clock to current simulation time
            dt = sim_time - (obj.clock.phi / (2*pi*obj.clock.f0));
            obj = obj.advance_time(dt);
            
            % Get current timestamp from clock
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Step FSM
            [obj.fsm, msgs] = obj.fsm.step(ts);
        end

        function obj = receive(obj, msg, sim_time)
            % Advance clock to message reception time
            dt = sim_time - (obj.clock.phi / (2*pi*obj.clock.f0));
            obj = obj.advance_time(dt);
            
            % Get timestamp when message is received
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Pass message to FSM
            obj.fsm = obj.fsm.receive(msg, ts);
        end
        
        function obj = advance_time(obj, dt)
            obj.clock = obj.clock.advance(dt);
        end
        
        function obj = syntonize(obj, rx_freq)
            obj.clock = obj.clock.syntonize(rx_freq);
        end

        function obj = offset_correction(obj)
            % Apply offset correction only once per sync cycle
            if obj.fsm.synced
                obj.clock = obj.clock.correct_offset(obj.fsm.last_offset);
                obj.fsm.synced = false;  % Reset sync flag after correction
            end
        end
    end
end

