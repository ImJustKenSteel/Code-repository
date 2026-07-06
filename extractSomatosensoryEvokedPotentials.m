function [LFPdata_fourHz, LFPdata_ramp] = extractSomatosensoryEvokedPotentials
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
f = dir('*CorrectMap*.mat');
load(f(1).name,'mapping');
load("events.mat");
[b, a] = butter(3, [60 300]/(30000/2));
LFPdata_fourHz = NaN(64,9,4500);
LFPdata_ramp = NaN(64,8,9,12000);
for channelNo=1:64
disp("Channel No = " + channelNo);
[data,ts] = load_open_ephys_data_faster("100_RhythmData_CH" + mapping.CorrectMap(channelNo) + ".continuous");    

data = filtfilt(b, a, data);
data=data*-1;
for binNo=1:length(events.fourHz)
for binNo=1:length(events.ramp)
[trialAve, ~] = multi_trial_matrix(data, ts, events.fourHz(:,binNo), 30000, [0.05 0.1]);
LFPdata_fourHz(channelNo,binNo,:) = mean(trialAve,2);
[trialAve, ~] = multi_trial_matrix(data, ts, events.ramp(:,binNo), 30000, [0.1 0.3]);
for intensityNo=1:8
LFPdata_ramp(channelNo,intensityNo,binNo,:) = trialAve(:,intensityNo);
end
end

end
save("LFPdata", "LFPdata_fourHz", "LFPdata_ramp");
end