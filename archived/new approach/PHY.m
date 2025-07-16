classdef PHY < handle
    properties
        clk LocalClock
        ptp PTPFSM
        tsu TSU
        rx_f
        rx_phi
        msg_queue
    end
    
    methods
        function obj = PHY(clk, ptp, tsu)
            obj.clk = clk;
            obj.ptp = ptp;
            obj.tsu = tsu;
        end
        
        function receive(obj, rx_f, rx_phi, msg)
            obj.rx_f = rx_f;
            obj.rx_phi = rx_phi;
            tsp = obj.tsu.getTimestamp();
            obj.ptp.tx_queue{end+1} = struct("msg",msg,"tsp", tsp);
        end

        function pkg = send(obj)
            if isempty(obj.ptp.rx_queue) == false
                tx_f = obj.clk.f;
                tx_phi = obj.clk.phi;
                msg = obj.ptp.rx_queue{1};
                pkg = [tx_f, tx_phi, msg];
                if length(obj.ptp.rx_queue) > 1
                    obj.ptp.rx_queue = obj.ptp.rx_queue{2:end};
                else
                    obj.ptp.rx_queue = {};
                end
            else
                pkg = [];

            end
        end


    end
end

