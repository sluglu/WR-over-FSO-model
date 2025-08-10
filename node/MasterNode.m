classdef MasterNode < PTPNode
    properties
        clock
        fsm
    end
    methods
        function obj = MasterNode(clock, fsm)
            if nargin >= 2
                % Validate that fsm is actually a MasterFSM
                if ~isa(fsm, 'MasterFSM')
                    error('MasterNode requires a MasterFSM object, got %s', class(fsm));
                end
                if ~isa(clock, 'MasterClock')
                    error('MasterNode requires a MasterClock object, got %s', class(clock));
                end
                obj.clock = clock;
                obj.fsm = fsm;
            else
                obj.clock = MasterClock();
                obj.fsm = MasterFSM();
            end
        end
    end
end
