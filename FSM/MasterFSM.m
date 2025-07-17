classdef MasterFSM < PTPFSM
    properties
        sync_interval
        next_sync_time
    end

    methods
        function obj = MasterFSM(sync_interval, verbose)
            obj@PTPFSM();
            if nargin > 0
                obj.sync_interval = sync_interval;
                if nargin > 1
                    obj.verbose = verbose;
                end
            else
                obj.sync_interval = 1;
            end
            obj.next_sync_time = 0;
        end

        function [obj, msgs] = step(obj, ts)
            msgs = {};

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
                        't4', obj.msg_queue{i}.ts ...
                    );
                    msgs{end+1} = delay_resp;
                else
                    remaining_msgs{end+1} = obj.msg_queue{i};
                end
            end
            obj.msg_queue = remaining_msgs;
        end
    end
end
