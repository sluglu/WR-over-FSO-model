clear; clc;

dt = 0.001;
sim_duration = 1;

delay = 10e-3;
drx = 1e-4;
dtx = 2e-4;

master = MasterNode(125e6, 1);
slave = SlaveNode(125e6);

sim_time = 0;
i = 1;
msg_queue = struct('target', {}, 'msg', {}, 'delivery_time', {});

while sim_time < sim_duration
    times(i) = sim_time;
    % STEP master and slave
    master.step(sim_time);
    slave.step(sim_time);

    % ENQUEUE messages from master
    msg = master.phy.send();
    while isempty(msg) == false
        msg_queue(end+1) = struct(...
            'target', 'slave', ...
            'msg', msg, ...
            'delivery_time', sim_time + delay + drx + dtx*j);
        msg = master.phy.send();
    end

    % ENQUEUE messages from master
    msg = slave.phy.send();
    while isempty(msg) == false
        msg_queue(end+1) = struct(...
            'target', 'slave', ...
            'msg', msg, ...
            'delivery_time', sim_time + delay + drx + dtx*j);
        msg = slave.phy.send();
    end

    % DELIVER messages whose time has come
    to_deliver = [msg_queue.delivery_time] == sim_time;
    for j = find(to_deliver)
        if strcmp(msg_queue(j).target, 'master')
            msg = msg_queue(j).msg;
            master.phy.receive(msg.rx_f, msg.rx_phi, msg.msg);
        else
            msg = msg_queue(j).msg;
            slave.phy.receive(msg.rx_f, msg.rx_phi, msg.msg);
        end
    end
    % Remove delivered messages from queue
    msg_queue = msg_queue(~to_deliver);
    
    next_step = dt;
    max_next_sim_time = min([msg_queue.delivery_time]);
    max_dt = max_next_sim_time - sim_time;
    if max_dt <= dt
        next_step = max_dt;
    end
    
    sim_time = sim_time + next_step;
    i = i + 1;
end