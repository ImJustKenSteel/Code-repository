if ~exist("events_sorted_KS.mat")
    originalDir=pwd;

    load("OEPInfo.mat")
    t_first=OEPinfo.t_first;
    Fs=30000;
    ts = 0:1/Fs:(1/Fs) * sum(OEPinfo.info.nsamples);
    load ("events_sorted.mat")
    mech_events=readtable("samples.xlsx");
    % load("ClusterList.mat")
    events.all.timestamp=events.all.timestamp-(t_first/30000);
    events.fourHz=events.fourHz-(t_first/30000);
    events.ramp=events.ramp-(t_first/30000);

    events.mech = reshape(mech_events.Var1(1:12), 4, 3);
    
    events.mech=(events.mech-(t_first/30000));
    save("events_sorted_ks.mat", "events");
else
    load("events_sorted_ks.mat")
end