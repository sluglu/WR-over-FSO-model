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
    end
end
