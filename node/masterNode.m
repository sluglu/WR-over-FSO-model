classdef MasterNode < PTPNode
    methods
        function obj = MasterNode(clock, timestamper, fsm)
            if nargin > 0
                args = {clock, timestamper, fsm};
            else
                args = {MasterClock(), timestamper(), MasterFSM()};
            end
            obj@PTPNode(args{:});
        end
    end
end

