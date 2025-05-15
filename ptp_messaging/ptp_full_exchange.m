function [offset_estimate, delay_estimate, real_offset, total_time, t1, t2, t3, t4, master, slave] = ptp_full_exchange(master, slave, delays)

    t0 = master.get_time;
    
    [t1, master] = send_sync(master);
    [t2, master, slave] = receive_sync(master, slave, delays.sync);
    [t3, master, slave] = send_delayreq(master, slave, delays.delayreq_send);
    [t4, master, slave] = receive_delayreq(master, slave, delays.delayreq_prop);

    [offset_estimate, delay_estimate] = ptp_exchange(t1, t2, t3, t4);

    real_offset = t2 - t1 - delays.sync;

    total_time = master.get_time - t0;
end

function [offset_sm_estimate, delta_ms_estimate] = ptp_exchange(t1, t2, t3, t4)
%PTP_EXCHANGE Estimate offset and delay from WR-style PTP exchange
% Inputs:
%   t1 : master sends Sync
%   t2 : slave receives Sync
%   t3 : slave sends Delay_Req
%   t4 : master receives Delay_Req
%
% Outputs:
%   offset_estimate : estimated offset (slave - master)
%   delay_estimate  : estimated one-way delay    

    delta_ms = t2 - t1;
    delta_sm = t4 - t3;

    delta_mm = delta_ms - delta_sm;

    alpha = delta_ms/delta_sm - 1;

    delta_ms_estimate = (1 + alpha)/(2+alpha) * delta_mm;
    
    offset_sm_estimate = t2 - t1 - delta_ms_estimate;
    
end

function [t1, clock] = send_sync(clock)
    t1 = clock.get_time();
end

function [t2, master, slave] = receive_sync(master, slave, delay_s)
    [master, slave] = advance_both_clocks(master, slave, delay_s);
    t2 = slave.get_time();
end

function [t3, master, slave] = send_delayreq(master, slave, delay_s)
    [master, slave] = advance_both_clocks(master, slave, delay_s);
    t3 = slave.get_time();
end

function [t4, master, slave] = receive_delayreq(master, slave, delay_s)
    [master, slave] = advance_both_clocks(master, slave, delay_s);
    t4 = master.get_time();
end


