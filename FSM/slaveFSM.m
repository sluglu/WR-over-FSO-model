classdef slaveFSM < handle
    properties
        clock
        syntonizer
        state = "WAIT_SYNC"
        t1
        t2
        t3
        t4
    end

    methods
        function obj = slaveFSM(clock)
            obj.clock = clock;
        end

        function [msgs, freq_out] = step(obj, sim_time, ts)
            msgs = [];
            freq_out = NaN;

            if obj.state == "SEND_DELAY_REQ"
                obj.t3 = ts;
                msg = struct("type", "DELAY_REQ", "arrival_time", sim_time + 50e-9, "payload", struct("t3", obj.t3));
                msgs = [msg];
                obj.state = "WAIT_DELAY_RESP";
            end
        end

        function receive(obj, msg, sim_time)
            t_now = obj.clock.get_time();
            switch msg.type
                case "SYNC"
                    obj.t2 = t_now;
                    obj.t1 = msg.payload.t1;
                    obj.state = "WAIT_FOLLOWUP";

                case "FOLLOW_UP"
                    if obj.state == "WAIT_FOLLOWUP"
                        offset = obj.t2 - msg.payload.t1;
                        obj.state = "SEND_DELAY_REQ";
                    end

                case "DELAY_RESP"
                    if obj.state == "WAIT_DELAY_RESP"
                        obj.t4 = msg.payload.t4;
                        delay = ((obj.t4 - obj.t1) - (obj.t3 - obj.t2)) / 2;
                        offset = (obj.t2 - obj.t1) - delay;
                        
                        obj.state = "WAIT_SYNC";
                    end
            end
        end
    end
end

