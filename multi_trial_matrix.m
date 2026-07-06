function [dataOut, tsOut, valid] = multi_trial_matrix(data, ts, event_ts, Fs, win)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to extract LFP data either side of a timestamped event
%
% INPUTS
%   data = continuous data
%   ts = timestamps corresponding to each sample in data
%   event_ts = timestamps of the events
%   Fs = sampling rate of data
%   win = number of seconds of data to extract around each event e.g. [1 1]
%         win(1) = seconds before event
%         win(2) = seconds after event
%
% OUTPUTS
%   dataOut = matrix containing data segments for each event - 1 column
%              per event
%   tsOut = timestamps to match the window around each event
%   valid = logical array to indicate if there are any events that were too
%           close to the beginning/end of the recording where there was
%           insufficient data to extract the full window. 
%
% EXAMPLE USAGE
%   dataOut = multi_trial_matrix(LFP, LFP_ts, choice_point_ts, 2048, [2 1]);
%       This would extract segments of LFP data covering the time period 2
%       seconds before, and 1 second after the choice point. 
%
% Tony Blockeel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5
    error('Need all arguments')
end

% Sanity check
if any(event_ts < ts(1)) || any(event_ts > ts(end))
    error("Event timestamps outside of input data")
end

% Sort events into ascending order
event_ts = sort(event_ts);

% Exclude events too close to the edges of the recording
valid = false(size(event_ts));
i = event_ts > ts(1)+win(1) & event_ts < ts(end)-win(2);
valid(i) = true;

if ~all(valid)
    warning("Some events too close to beginning/end of recording and were excluded - dataOut padded with NaNs")
end

% How many data samples are there associated with each segment?
samples_pre = round(win(1) * Fs);
samples_post = round(win(2) * Fs);
samples_per_event = samples_pre + samples_post;

% How many valid events are there
no_events = length(event_ts);

% Preallocate matrix to store output
dataOut = NaN(samples_per_event, no_events);

% If data has been downsampled events may not fall exactly on a sample, so
% find closest.
inds = discretize(event_ts,ts-(diff(ts(1:2))*.5));

for n = 1:no_events

    if valid(n)
        % Extract the correct length of data following the start of each event
        dataOut(:,n) = data(inds(n) - samples_pre:inds(n) + samples_post - 1);
    end

end

% Calculate timsstamps corresponding to the output matrix. 
tsOut = linspace(-win(1),win(2) - (1/Fs), size(dataOut,1));
