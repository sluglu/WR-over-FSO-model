classdef MasterFSM < PTPFSM
    properties
        sync_interval
        next_sync_time
        last_cts
        last_fts
    end

    methods
        function obj = MasterFSM(sync_interval, tsu)
            obj@PTPFSM(tsu);
            if nargin > 0
                obj.sync_interval = sync_interval;
            else
                obj.sync_interval = 1;
            end
            obj.next_sync_time = 0;
        end

        function step(obj)
            ts = obj.tsu.getTimestamp();
            
            if ts >= obj.next_sync_time
                % Send SYNC
                sync_msg = struct( ...
                    'type', 'SYNC' ...
                );

                % Send FOLLOW_UP
                followup_msg = struct( ...
                    'type', 'FOLLOW_UP', ...
                    't1', ts ...
                );

                obj.tx_queue{end+1} = {sync_msg, followup_msg};
                obj.next_sync_time = obj.next_sync_time + obj.sync_interval;
                
            end

            % Respond to DELAY_REQ
            remaining_msgs = {};
            for i = 1:length(obj.rx_queue)
                msg = obj.rx_queue{i}.msg;
                if strcmp(msg.type, 'DELAY_REQ')
                    delay_resp = struct( ...
                        'type', 'DELAY_RESP', ...
                        't4', obj.rx_queue{i}.tsp ...
                    );
                    obj.tx_queue{end+1} = delay_resp;
                else
                    remaining_msgs{end+1} = obj.rx_queue{i};
                end
            end
            obj.rx_queue = remaining_msgs;
        end
    end
end
