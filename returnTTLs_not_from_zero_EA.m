function [TTLs] = returnTTLs_not_from_zero_EA(dirname,file_prefix, file_postfix)
%% returnTTLs_not_from_zero_EA
% This function takes continuous OEP data and returns TTL input on
% each of the 8 digital channels, alongside the manually entered information.
% Timestamps are NOT relative to a zero starting point so should not be
% used with clustered data from PHY.
% NB: this can be fixed by getting the offset from the messages.events file
% Expects input arguments (strings) in the form.
% 'dirname' is the path to the folder containing the OEP data.

% dirname = string of path to folder with .continuous files
% file_prefix, file_postfix = extra bits around ch number in the filenames

% Anna Sales 31/07/2020
% modified by Elise Ajay Apr 10 2024

%% Here we go~
% Work out what files are in the directory given, and the format of their
% names
file_list=dir(dirname);
chk4cont = regexp({file_list.name}, '.continuous', 'once');
cont_matches=find(~cellfun(@isempty, chk4cont));

% if we found .continuous files, get the TTLs
if ~isempty(cont_matches)
    fprintf('\n Continuous data found...reading example file....\n')
    ex_file = file_prefix + "*" + file_postfix + '.continuous';

    % Load in some example data and the events file
    [event_data, event_ts,  event_info] = load_open_ephys_data("D:\For kilosort\Flexible electrode\2024-05-14_15-38-18\Record Node 113\100_RhythmData_CH1.continuous");

    % Overwrite if you want to check something specific...
    %ex_file = ["100_RhythmData-A-A_CH1_3.continuous"];
    %[event_data, event_ts, event_info] = load_open_ephys_data_ea(dirname +'100_RhythmData-B' +file_postfix +'.events');

    % Load manual events from messages.events file
    manual_events = fileread(dirname +'\messages.events');
    fs=30000;

    % parse the events file (this is a text file containing manually entered info):
    find_newlines=regexp(manual_events, '\n');
    messages={};
    if ~isempty(find_newlines)
        for n=2:length(find_newlines)  %ignore the first one as it's always an internal messages
            if n<length(find_newlines)
                messages{n-1}=manual_events(find_newlines(n):find_newlines(n+1)-1);
            else
                messages{n-1}=manual_events(find_newlines(n):end);
            end
        end
        messages(end)=[]; %last one is nonsense also.
    end

    % Check the recording isn't split into blocks.
    ts_gaps=diff(event_ts);  %index n of lts_gaps is the gap between TTL n+1 and n
    [l_inds, ~]=find(ts_gaps>1); %pulls out the gaps between timestamps that are are more than 1s apart
    block_times(:,1)=event_ts([1; (l_inds+1)]);  %first col is starts
    block_times(:,2)=event_ts( [l_inds; length(event_ts)]);   %second col is ends
    num_block=length(block_times(:, 1));

    if num_block>1
        fprintf('WARNING -  this recording is in multiple blocks ');
    else

        %  Extract TTLs on channels 1-8
        TTLtimes=cell(1,8);
        for iTTL=1:8
            TTL_ts=unique(event_ts( find(event_data==iTTL-1)));  %find of elements which have footshock timestamp.
            TTL_ts=TTL_ts* (1/fs);  %offset to start at zero, like the PHY output.
            TTLtimes{iTTL}=TTL_ts;
        end

        % now do the manual events (i.e. messages entered in box)
        TTL_times=[];
        TTL_labels={};

        for m=1:length(messages)
            [time, label]=strtok(messages{m}, ' ');
            if ~isempty(label)
                TTL_times(m)=(str2num(time)* (1/fs));
                TTL_labels{m}=label;
            end
        end

        manTTL.TTL_times=TTL_times;
        manTTL.TTL_labels=TTL_labels;


        TTLs.digital=TTLtimes;
        TTLs.manual=manTTL;
        save(dirname +'TTLs', 'TTLs');
    end
else
    fprintf('\n No continuous files found.')
end

