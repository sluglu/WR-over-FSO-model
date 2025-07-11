classdef MasterNode
    properties
        clock MasterClock
        fsm MasterFSM
        timestamper Timestamper
        old_time
    end
    methods
        function obj = MasterNode(clock, timestamper, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.timestamper = timestamper;
                obj.fsm = fsm;
            else
                obj.clock = MasterClock();
                obj.timestamper = timestamper();
                obj.fsm = MasterFSM();
            end
            obj.old_time = 0;
        end

        function [obj, msgs] = step(obj, sim_time)
            dt = sim_time - obj.old_time;
            obj.clock = obj.clock.advance(dt);
            [cts, fts] = obj.timestamper.getTimestamp(obj.clock);
            [obj.fsm, msgs] = obj.fsm.step(fts);
            obj.old_time = sim_time;
        end

        function obj = receive(obj, msg)
            [cts, fts] = obj.timestamper.getTimestamp(obj.clock);
            obj.fsm = obj.fsm.receive(msg, fts);
        end
    end
end

