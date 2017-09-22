function [signal_avg_out] ...
    = average_trials(signal,num_trials,bufSize)


%-- offset all trials to start at t=0
time_idx = 1;
for trial_idx = 1:num_trials
    signal{trial_idx}(:,time_idx) = signal{trial_idx}(:,time_idx)...
        -signal{trial_idx}(1,time_idx);
end

%-- find the smallest size of a given trial (other trials will simply be
% cropped to this size
signal_trialSize(num_trials) = zeros;
for trial_idx = 1:num_trials
    signal_trialSize(trial_idx) = size(signal{trial_idx},1);
end

min_signal_trialSize = min(signal_trialSize);

signal_avg(bufSize,2) = zeros;
for val_idx = 1:min_signal_trialSize
    signal_avg(val_idx,1) = signal{1}(val_idx,1);
    for trial_idx = 1:num_trials
        signal_avg(val_idx,2) = signal_avg(val_idx,2) + signal{trial_idx}(val_idx,2);
    end
end


signal_avg_out(:,1) = signal_avg(signal_avg(:,2)~=0,1);
signal_avg_out(:,2) = signal_avg(signal_avg(:,2)~=0,2)/num_trials;
%-- 

%-- 
