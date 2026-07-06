function info = make_bin_in_blocks_ks()
% Import and chunking of Open Ephys data into .bin files with artefact removal.
% Processes data into suitable .bin files for Kilosort clustering.
% Channels are ordered based on `mapping.CorrectMap` which specifies the order.

PathName = pwd; % Ensure you are in the directory with the necessary files
load('OEPInfo.mat');  % File created by the artefact removal script
load('CorrectMap.mat');  % Load the mapping table (assumed to be a structure)

fileInfo = OEPinfo.info;
input_directory = PathName;
output_directory = input_directory;
nChans = 64;
fileInfo.header.sampleRate=30000;

% Use CorrectMap from mapping for channel order
ChSaved = mapping.CorrectMap; % CorrectMap should contain indices in the desired order

% Check if ChSaved matches the expected number of channels
assert(length(ChSaved) == nChans, 'ChSaved must match the number of channels.');

file_prefix = '100_RhythmData_CH';
testfn = ['100_RhythmData_CH' num2str(1) '.mat'];

% Specify block length in minutes
BlkLengthMin = 10;

% Calculate file and block length details
fLength = fileInfo.header.blockLength * length(fileInfo.ts);  % File length in samples
BlkLength = BlkLengthMin * 60 * fileInfo.header.sampleRate;   % Block length in samples
BlksizeGB = (BlkLength * 16 * numel(ChSaved)) / (1e9 * 8);    % Block size in GB
noBlks = ceil(fLength / BlkLength);                          % Number of data blocks
bitVolts = fileInfo.header.bitVolts;

fprintf('>>> Recording is %d seconds long (%.2f hours).\n', ...
    round(fLength / fileInfo.header.sampleRate), ...
    round(fLength / fileInfo.header.sampleRate) / 3600);
fprintf('>>> Writing data as %d blocks of %d minutes, each block is %.3f GB.\n', ...
    noBlks, BlkLengthMin, BlksizeGB);

% Cache filenames
%fname_in = str(1, length(ChSaved));
for iCh = 1:length(ChSaved)
    fname_in{iCh} = [input_directory filesep file_prefix int2str(ChSaved(iCh)) '.mat'];
end
fname_out = cell(1, noBlks);
for iBlk = 1:noBlks
    fname_out{iBlk} = [output_directory filesep 'Raw_Part_' num2str(iBlk) '.bin'];
end

% Loop across time in blocks
for iBlk = 1:noBlks
    t1 = tic;
    fprintf('>>> Starting Block %d of %d.\n', iBlk, noBlks);

    % Preallocate block data based on block size
    if iBlk ~= noBlks
        data = cellfun(@(x) zeros(BlkLength, 1), cell(1, length(ChSaved)), 'UniformOutput', false);
    else
        data = cellfun(@(x) zeros(fLength - BlkLength * (noBlks - 1), 1), cell(1, length(ChSaved)), 'UniformOutput', false);
    end

    flag_ = cell(1, length(ChSaved));
    t2 = tic;

    % Load data for each channel based on ChSaved order
    for iCh = 1:length(ChSaved)
        fprintf('\n Channel %d ', ChSaved(iCh));
        try
            % Concatenate elements if `fname_in{iCh}` has multiple string parts
            filePath = fname_in{iCh};  % Ensure it's one continuous string

            % Load the file using the corrected path
            data_struct = load(filePath);            
            data_ = data_struct.edited_file;
            data_(1:BlkLength * (iBlk - 1)) = [];  % Remove processed data

            if iBlk ~= noBlks
                data{iCh} = data_(1:BlkLength);
            else
                data{iCh} = data_(1:end);
            end

            flag_{iCh} = 1;
        catch
            fprintf('WARNING Conversion error for channel %d! Padding with zeros.\n', ChSaved(iCh));
            flag_{iCh} = 0;
        end
    end

    % Convert to matrix and scale by bitVolts
    data = cell2mat(data) / bitVolts;
    info.flag(:, iBlk) = cell2mat(flag_);
    fprintf('>>> Import took %ds, now writing to .bin ...\n', round(toc(t2)));

    % Write this block to .bin file
    t3 = tic;
    fid = fopen(fname_out{iBlk}, 'w');
    fwrite(fid, double(data)', 'int16');
    fclose(fid);
    fprintf('>>> Writing block %d to .bin file (%s) took %ds.\n', iBlk, fname_out{iBlk}, round(toc(t3)));
    fprintf('>>> Block %d done. Took %ds.\n', iBlk, round(toc(t1)));
    data = [];
end

% Output info structure
info.input_directory = input_directory;
info.output_directory = output_directory;
info.fname_in = fname_in;
info.fname_out = fname_out;
info.fLength = fLength;
info.noBlks = noBlks;
info.BlkLength = BlkLength;
info.BlkLengthMin = BlkLengthMin;
info.BlksizeGB = BlksizeGB;
info.ChSaved = ChSaved;

% Concatenate files
nBinFiles = numel(dir([PathName filesep '*.bin']));
binFiles = dir([PathName filesep '*.bin']);
fileOut = fopen([PathName filesep 'dataALL.bin'], 'w');

for i = 1:nBinFiles
    disp(['Writing file Raw_Part_' num2str(i) '.bin']);
    fileIn = fopen([PathName filesep 'Raw_Part_' num2str(i) '.bin'], 'r');
    temp = fread(fileIn);
    fwrite(fileOut, temp);
    fclose(fileIn);
end

fprintf('\nDone\n');
fclose(fileOut);
