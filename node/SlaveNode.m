classdef SlaveNode
    properties
        clock SlaveClock
        fsm SlaveFSM
        old_time
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
            obj.old_time = 0;
        end

        function [obj, msgs] = step(obj, sim_time, rx_freq)
            dt = sim_time - obj.old_time;
            obj.clock = obj.clock.syntonize(rx_freq);
            if(obj.fsm.synced)
                obj.clock = obj.clock.correct_offset(obj.fsm.last_offset);
            end
            obj.clock = obj.clock.advance(dt);
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            [obj.fsm, msgs] = obj.fsm.step(ts);
            obj.old_time = sim_time;
        end

        function obj = receive(obj, msg)
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            obj.fsm = obj.fsm.receive(msg, ts);
        end

        function obj = syntonize(obj, rx_freq)
            obj.clock = obj.clock.syntonize(rx_freq);
        end
    end
end

