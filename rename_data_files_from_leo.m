% Rename raw files from Leo Gizzi's workflows for EMG experiments
% Extracts files name from the comment field and strips all special
% characters 
%
% - only needed once per experiment set -
%
% Harnoor Saini
% August 2017
%

clear

%--- read in the file names

% current dir
currdir = pwd;

% directory of raw files
rawdir = 'C:\Users\saini\Documents\PhD_Local_C\51_Raw_data\2017_MUTA\EMG\force_results';

% change to raw file directory
cd(rawdir)

% get list of all subdirectories
files = dir;
subdirs = {files([files.isdir]).name};
subdirs = subdirs(~ismember(subdirs,{'.','..'}));


% Get all results files in the raw directory
for subdir_idx = 1:size(subdirs,2)
    % change to raw file sub-directory
    subdirpath = [rawdir '\' subdirs{subdir_idx}];
    cd(subdirpath)
    
    % add the path so it can still be read from after changing back
    addpath(subdirpath)
    
    % list all .mat files in sub-directory
    files = dir('*.mat');

    % change back to the current (script) directory
    cd(currdir)

%--- read in the experiment IDs

    for file_idx = 1:size(files,1)
        fname = [subdirpath '\' files(file_idx).name];
        load(fname)
        outname = notes.recording_comments;
        outname = regexprep(outname,'[^a-zA-Z0-9]','');
        outname = ['data\' outname '.mat'];
        copyfile(fname,outname)
        clear fname
        clear outname
    end
end