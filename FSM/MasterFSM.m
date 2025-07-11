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

        function [obj, msgs] = step(obj, cts, fts)
            msgs = {};

            if cts >= obj.next_sync_time
                % Send SYNC
                sync_msg = struct( ...
                    'type', 'SYNC' ...
                );

                % Send FOLLOW_UP
                followup_msg = struct( ...
                    'type', 'FOLLOW_UP', ...
                    't1', cts ...
                );

                msgs = {sync_msg, followup_msg};
                obj.next_sync_time = obj.next_sync_time + obj.sync_interval;
            end

            % Respond to DELAY_REQ
            remaining_msgs = {};
            for i = 1:length(obj.msg_queue)
                msg = obj.msg_queue{i}.msg;
                if strcmp(msg.type, 'DELAY_REQ')
                    delay_resp = struct( ...
                        'type', 'DELAY_RESP', ...
                        't4', obj.msg_queue{i}.fts ...
                    );
                    msgs = {delay_resp};
                else
                    remaining_msgs{end+1} = msg;
                end
            end
            obj.msg_queue = remaining_msgs;
        end
    end
end
