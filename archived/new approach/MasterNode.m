classdef MasterNode < handle
    properties
        clk LocalClock
        ptp PTPFSM
        tsu TSU
        phy PHY
        phase_detector PhaseDetector
        old_time
    end
    methods
        function obj = MasterNode(f, sync_interval)
            obj.clk = LocalClock(f);
            obj.ptp = MasterFSM(sync_interval, obj.tsu);
            obj.phy = PHY(obj.clk, obj.ptp, obj.tsu);
            obj.phase_detector = PhaseDetector(obj.clk, obj.phy);
            obj.tsu = TSU(obj.clk, obj.phase_detector);
            obj.phy.tsu = obj.tsu;
            obj.ptp.tsu = obj.tsu;
            obj.old_time = 0;
        end

        function obj = step(obj, sim_time)
            dt = sim_time - obj.old_time;
            obj.clk.advance(dt);
            obj.ptp.step();
            obj.old_time = sim_time;
        end
    end
end

