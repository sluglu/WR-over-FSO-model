classdef MasterFSM < PTPFSM
    properties
        sync_interval
        next_sync_time
        last_cts
        last_fts
    end

    methods
        function obj = MasterFSM(sync_interval)
            obj@PTPFSM();
            if nargin > 0
                obj.sync_interval = sync_interval;
            else
                obj.sync_interval = 1;
            end
            obj.next_sync_time = 0;
        end

        function msgs = step(obj, sim_time, cts, fts)
            msgs = {};

            if sim_time >= obj.next_sync_time
                % Send SYNC
                sync_msg = struct( ...
                    'type', 'SYNC', ...
                    'timestamp', sim_time, ...
                    'cts', cts, ...
                    'fts', fts ...
                );

                % Send FOLLOW_UP
                followup_msg = struct( ...
                    'type', 'FOLLOW_UP', ...
                    't1', sim_time, ...
                    'cts', cts, ...
                    'fts', fts ...
                );

                msgs = {sync_msg, followup_msg};
                obj.last_cts = cts;
                obj.last_fts = fts;
                obj.next_sync_time = obj.next_sync_time + obj.sync_interval;
            end

            % Respond to DELAY_REQ
            remaining_msgs = {};
            for i = 1:length(obj.msg_queue)
                msg = obj.msg_queue{i};
                if strcmp(msg.type, 'DELAY_REQ')
                    delay_resp = struct( ...
                        'type', 'DELAY_RESP', ...
                        't4', sim_time, ...
                        'orig_cts', msg.cts, ...
                        'orig_fts', msg.fts ...
                    );
                    msgs{end+1} = delay_resp;
                else
                    remaining_msgs{end+1} = msg;
                end
            end
            obj.msg_queue = remaining_msgs;
        end
    end
end
