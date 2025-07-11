classdef SlaveNode
    properties
        clock SlaveClock
        fsm SlaveFSM
        timestamper Timestamper
        syntonizer L1Syntonizer
        old_time
    end

    methods
        function obj = SlaveNode(clock, timestamper, fsm, syntonizer)
            if nargin > 0
                obj.clock = clock;
                obj.timestamper = timestamper;
                obj.fsm = fsm;
                obj.syntonizer = syntonizer;
            else
                obj.clock = SlaveClock();
                obj.timestamper = timestamper();
                obj.fsm = SlaveFSM();
                obj.syntonizer = L1Syntonizer();
            end
            obj.old_time = 0;
        end

        function [obj, msgs] = step(obj, sim_time)
            dt = sim_time - obj.old_time;
            obj.clock = obj.clock.advance(dt);
            [cts, fts] = obj.timestamper.getTimestamp(obj.clock);
            [obj.fsm, msgs] = obj.fsm.step(cts);
            obj.old_time = sim_time;
        end

        function obj = receive(obj, msg)
            [cts, fts] = obj.timestamper.getTimestamp(obj.clock);
            obj.fsm = obj.fsm.receive(msg, fts);
        end

        function obj = syntonize(obj, rx_freq)
            obj.clock = obj.clock.syntonize(rx_freq);
        end
    end
end

