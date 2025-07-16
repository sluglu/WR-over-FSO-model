classdef MasterNode
    properties
        clock MasterClock
        fsm MasterFSM
        old_time
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
            obj.old_time = 0;
        end

        function [obj, msgs] = step(obj, sim_time)
            dt = sim_time - obj.old_time;
            obj.clock = obj.clock.advance(dt);
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            [obj.fsm, msgs] = obj.fsm.step(ts);
            obj.old_time = sim_time;
        end

        function obj = receive(obj, msg)
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            obj.fsm = obj.fsm.receive(msg, ts);
        end
    end
end

