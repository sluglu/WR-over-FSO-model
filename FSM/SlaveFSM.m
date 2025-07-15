classdef SlaveFSM < PTPFSM
    properties
        t1  % master sends SYNC (from FOLLOW_UP)
        t2  % slave receives SYNC
        t3  % slave sends DELAY_REQ
        t4  % master replies with DELAY_RESP

        waiting_followup
        waiting_delay_resp
        synced

        last_offset
        last_delay
    end

    methods
        function obj = SlaveFSM()
            obj@PTPFSM();
            obj.synced = false;
            obj.waiting_followup = false;
            obj.waiting_delay_resp = false;
            obj.last_offset = NaN;
            obj.last_delay = NaN;
        end

        function [obj, msgs] = step(obj, cts)
            msgs = {};
            remaining_msgs = {};

            for i = 1:length(obj.msg_queue)
                msg = obj.msg_queue{i}.msg;
                msg_fts = obj.msg_queue{i}.fts;

                switch msg.type
                    case 'SYNC'
                        obj.t2 = msg_fts;
                        obj.waiting_followup = true;

                    case 'FOLLOW_UP'
                        obj.t1 = msg.t1 ;
                        obj.waiting_followup = false;

                        % Send DELAY_REQ
                        obj.t3 = cts;
                        delay_req = struct( ...
                            'type', 'DELAY_REQ' ...
                        );
                        msgs{end+1} = delay_req;
                        obj.waiting_delay_resp = true;

                    case 'DELAY_RESP'
                        if obj.waiting_delay_resp
                            obj.t4 = msg.t4;
                            obj.waiting_delay_resp = false;
                            obj.synced = true;

                            % Compute offset and delay
                            obj.last_delay = ((obj.t2 - obj.t1) + (obj.t4 - obj.t3)) / 2;
                            obj.last_offset = ((obj.t2 - obj.t1) - (obj.t4 - obj.t3)) / 2;

                            if obj.verbose
                                fprintf("t1 = %.9f | t2 = %.9f | t3 = %.9f | t4 = %.9f\n", obj.t1, obj.t2, obj.t3, obj.t4);
                                fprintf("Offset = %.12f | Delay = %.12f\n", obj.last_offset, obj.last_delay);
                                %fprintf('[SYNCED] Offset = %.3e s | Delay = %.3e s\n', ...
                                %obj.last_offset, obj.last_delay);
                            end
                        end

                    otherwise
                        % Keep unrecognized messages
                        remaining_msgs{end+1} = obj.msg_queue{i};
                end
            end

            obj.msg_queue = remaining_msgs;
        end
    end
end


