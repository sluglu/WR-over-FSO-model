classdef PTPFSM
    properties
        state
        msg_queue
        verbose
    end

    methods
        function obj = PTPFSM()
            obj.state = 'IDLE';
            obj.msg_queue = {};
            obj.verbose = true;
        end

        function [obj, msgs] = step(obj, cts) 
            msgs = {};
        end 

        function print_msg(obj, msg, fts)
            % Display base info
            fprintf('[%s] Received message at fts = %.9f | type = %s', ...
                class(obj), fts, msg.type);
        
            % Display optional timestamp fields if present
            for field = {'t1', 't2', 't3', 't4'}
                fname = field{1};
                if isfield(msg, fname)
                    fprintf(' | %s = %.9f', fname, msg.(fname));
                end
            end
            fprintf('\n');
        end

        function obj = receive(obj, msg, fts)
            obj.msg_queue{end+1} = struct('msg', msg, 'fts', fts);
            if obj.verbose
                print_msg(obj, msg, fts)
            end

        end
    end
end
