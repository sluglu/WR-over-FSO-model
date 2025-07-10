classdef SlaveNode < PTPNode
    properties
        syntonizer L1Syntonizer
    end

    methods
        function obj = SlaveNode(clock, timestamper, fsm, syntonizer)
            if nargin > 0
                args = {clock, timestamper, fsm};
            else
                args = {MasterClock(), timestamper(), SlaveFSM()};
                syntonizer = L1Syntonizer();
            end
            obj@PTPNode(args{:});
            obj.syntonizer = syntonizer;
        end

        function msgs = step(obj, sim_time, rx_freq)
            dt = sim_time - obj.old_time;
            obj.clock = obj.syntonizer.syntonize(rx_freq, obj.clock);
            obj.clock = obj.clock.advance(dt);
            cts = obj.timestamper.getCoarsePhase(obj.clock);
            fts = obj.timestamper.getFinePhase(obj.clock);
            msgs = obj.fsm.step(sim_time, cts, fts);
            obj.old_time = sim_time;
        end
    end
end

