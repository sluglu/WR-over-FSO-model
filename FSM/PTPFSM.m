classdef PTPFSM < handle
    properties
        state
        msg_queue
    end

    methods
        function obj = PTPFSM()
            obj.state = 'IDLE';
            obj.msg_queue = {};
        end

        function msgs = step(obj, sim_time, cts, fts)
            msgs = {};
        end

        function receive(obj, msg, sim_time)
            obj.msg_queue{end+1} = msg;
        end
    end
end
