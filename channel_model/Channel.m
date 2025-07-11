classdef Channel < handle
    properties
        base_delay = 50e-9;
        doppler_factor = 0;
        noise_std = 0;
        queue = struct('arrival_time', {}, 'msg', {}, 'dst', {});
    end

    methods
        function apply_doppler(obj, freq)
            obj.doppler_factor = freq * 1e-9; % example mapping
        end

        function transmit(obj, msgs, freq_out, src, dst, sim_time)
            delay = obj.base_delay * (1 + obj.doppler_factor);
            for i = 1:length(msgs)
                m = msgs(i);
                msg_copy = m;
                msg_copy.arrival_time = sim_time + delay + randn * obj.noise_std;
                obj.queue(end+1) = struct('arrival_time', msg_copy.arrival_time, 'msg', msg_copy, 'dst', dst);
            end
        end

        function deliver(obj, sim_time, master, slave)
            idx = find([obj.queue.arrival_time] <= sim_time);
            for i = idx
                entry = obj.queue(i);
                if entry.dst == "slave"
                    slave.receive(entry.msg, sim_time);
                    if isfield(entry.msg, 'type') && entry.msg.type == "SYNC"
                        slave.apply_frequency(slave.clock.nominal_freq * (1 + obj.doppler_factor));
                    end
                else
                    master.receive(entry.msg, sim_time);
                end
            end
            obj.queue(idx) = [];
        end
    end
end

