classdef PTPFSM
    properties
        state
        msg_queue
    end

    methods
        function obj = PTPFSM()
            obj.state = 'IDLE';
            obj.msg_queue = {};
        end

        function [obj, msgs] = step(obj, cts) 
            msgs = {};
        end 

        function obj = receive(obj, msg, fts)
            obj.msg_queue{end+1} = struct('msg', msg, 'fts', fts);
        end
    end
end
