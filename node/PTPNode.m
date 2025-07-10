classdef PTPNode < handle
    properties
        clock WRClock
        timestamper Timestamper
        fsm
        old_time
    end

    methods
        function obj = PTPNode(clock, timestamper, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.timestamper = timestamper;
                obj.fsm = fsm;
            else
                obj.clock = WRClock();
                obj.timestamper = timestamper();
                obj.fsm = PTPFSM();
            end
            obj.old_time = 0;
        end

        function msgs = step(obj, sim_time)
            dt = sim_time - obj.old_time;
            obj.clock = obj.clock.advance(dt);
            cts = obj.timestamper.getCoarsePhase(obj.clock);
            fts = obj.timestamper.getFinePhase(obj.clock);
            msgs = obj.fsm.step(sim_time, cts, fts);
            obj.old_time = sim_time;
        end

        function receive(obj, msg, sim_time)
            obj.fsm.receive(msg, sim_time);
        end
    end
end 
