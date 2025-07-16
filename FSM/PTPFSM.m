classdef PTPFSM
    properties
        msg_queue
        verbose
    end

    methods
        function obj = PTPFSM()
            obj.msg_queue = {};
            obj.verbose = true;
        end

        function print_msg(obj, msg, ts)
            % Display base info
            fprintf('[%s] Received message at ts = %.9e | type = %s', ...
                class(obj), ts, msg.type);
        
            % Display optional timestamp fields if present
            for field = {'t1', 't2', 't3', 't4'}
                fname = field{1};
                if isfield(msg, fname)
                    fprintf(' | %s = %.9e', fname, msg.(fname));
                end
            end
            fprintf('\n');
        end

        function obj = receive(obj, msg, ts)
            obj.msg_queue{end+1} = struct('msg', msg, 'ts', ts);
            if obj.verbose
                print_msg(obj, msg, ts)
            end

        end
    end
end
