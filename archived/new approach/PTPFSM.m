classdef PTPFSM < handle
    properties
        tx_queue
        rx_queue
        verbose
        tsu TSU
    end

    methods
        function obj = PTPFSM(tsu)
            obj.tsu = tsu;
            obj.tx_queue = {};
            obj.rx_queue = {};
            obj.verbose = true;
        end

        % function print_msg(obj, msg, fts)
        %     % Display base info
        %     fprintf('[%s] Received message at fts = %.9f | type = %s', ...
        %         class(obj), fts, msg.type);
        % 
        %     % Display optional timestamp fields if present
        %     for field = {'t1', 't2', 't3', 't4'}
        %         fname = field{1};
        %         if isfield(msg, fname)
        %             fprintf(' | %s = %.9f', fname, msg.(fname));
        %         end
        %     end
        %     fprintf('\n');
        % end
    end
end
