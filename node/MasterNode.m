classdef MasterNode
    properties
        clock MasterClock
        fsm MasterFSM
    end
    
    methods
        function obj = MasterNode(clock, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.fsm = fsm;
            else
                obj.clock = MasterClock();
                obj.fsm = MasterFSM();
            end
        end

        function [obj, msgs] = step(obj, sim_time)
            % Advance clock to current simulation time
            obj = obj.advance_to_time(sim_time);
            
            % Get current timestamp from clock
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Step FSM
            [obj.fsm, msgs] = obj.fsm.step(ts);
        end

        function obj = receive(obj, msg, sim_time)
            % Advance clock to message reception time
            obj = obj.advance_to_time(sim_time);
            
            % Get timestamp when message is received
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Pass message to FSM
            obj.fsm = obj.fsm.receive(msg, ts);
        end
        
        function obj = advance_to_time(obj, target_time)
            % Get current time from clock
            current_time = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Calculate time difference
            dt = target_time - current_time;
            
            % Only advance if we're moving forward in time
            if dt > 0
                obj.clock = obj.clock.advance(dt);
            end
        end
    end
end
