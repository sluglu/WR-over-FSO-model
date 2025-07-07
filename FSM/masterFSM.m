classdef masterFSM < handle
    properties
        state = "IDLE"
        clock
        sync_period = 200e-9
        followup_delay = 20e-9
        delayreq_delay = 50e-9
        last_sync_time = -Inf
        next_followup_time = Inf
        t1
    end

    methods
        function obj = masterFSM(clock)
            obj.clock = clock;
        end

        function [msgs, freq_out] = step(obj, sim_time, ts)
            msgs = [];
            freq_out = obj.clock.get_frequency();
            switch obj.state
                case "IDLE"
                    if sim_time >= obj.last_sync_time + obj.sync_period
                        obj.t1 = ts;
                        msg = struct("type", "SYNC", "arrival_time", sim_time + 50e-9, "payload", struct("t1", obj.t1));
                        msgs = [msg];
                        obj.last_sync_time = sim_time;
                        obj.next_followup_time = sim_time + obj.followup_delay;
                        obj.state = "WAIT_FOLLOWUP";
                    end

                case "WAIT_FOLLOWUP"
                    if sim_time >= obj.next_followup_time
                        msg = struct("type", "FOLLOW_UP", "arrival_time", sim_time + 50e-9, "payload", struct("t1", obj.t1));
                        msgs = [msg];
                        obj.state = "IDLE";
                    end
            end
        end

        function receive(obj, msg, sim_time)
            % Handle DELAY_REQ from slave
            if msg.type == "DELAY_REQ"
                t4 = obj.clock.get_time();
                response = struct("type", "DELAY_RESP", "arrival_time", sim_time + 50e-9, "payload", struct("t4", t4));
                obj.last_resp = response;
            end
        end
    end
end
