classdef slaveNode < PTPNode
    properties
        syntonizer
    end

    methods
        %function obj = slaveNode(clock, timestamper, syntonizer, fsm)
        function obj = slaveNode(clock, timestamper, syntonizer)
            %fsm = slaveFSM(clock);
            obj@PTPNode(clock, timestamper);
            obj.syntonizer = syntonizer;
        end

        %function [msgs, freq_out] = step(obj, sim_time, rx_freq, fsm)
        function [msgs, freq_out] = step(obj, sim_time, rx_freq)
            dt = sim_time - obj.old_time;
            obj.clock = obj.syntonizer.syntonize(rx_freq, obj.clock);
            obj.clock = obj.clock.advance(dt);
            cts = obj.timestamper.getCoarsePhase(obj.clock);
            fts = obj.timestamper.getFinePhase(obj.clock);
            %[msgs, freq_out] = obj.fsm.step(sim_time, cts, fts);
            obj.old_time = sim_time;
        end
    end
end

