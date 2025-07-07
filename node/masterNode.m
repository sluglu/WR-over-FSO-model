classdef masterNode < PTPNode
    methods
        function obj = masterNode(clock, timestamper)
            %fsm = masterFSM(clock);
            obj@PTPNode(clock, timestamper);
        end
    end
end

