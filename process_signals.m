function [alpha_trials,muscle_force, EMG] = ...
    process_signals(force, EMG, trial,bufSize,max_EMG_voltage,moment_arm,sample_tstep)



disp(['Maximum of current EMG signal is: ' num2str(max(EMG(:,2))) ] )
disp ' '


disp(['Filtering EMG signal'])
disp ' '

% low pass "zero phase" filter;
d1 = designfilt('lowpassiir','FilterOrder',5, ...
   'HalfPowerFrequency',0.85,'DesignMethod','butter');
filt_EMG = filtfilt(d1,EMG);




% normalise EMG signal to find activation (what about time delay?)
alpha(:,2) = filt_EMG(:,2)/max_EMG_voltage;
alpha(:,1) = [filt_EMG(:,1)];


IDX_alpha = zeros(bufSize,3);
IDX_f = zeros(bufSize,3);
% find corresponding indices
for trial_idx = 1:size(trial,1)
    tmp = find(alpha(:,1)>trial(trial_idx,1) ... 
        -sample_tstep & alpha(:,1)<trial(trial_idx,2));
    tmp_f = find(force(:,1)>trial(trial_idx,1) ... 
        -sample_tstep & force(:,1)<trial(trial_idx,2));
    if size(tmp,1) < 1000 && size(tmp_f,1) < 1000
        IDX_alpha(1:size(tmp,1),trial_idx) = tmp;
        IDX_f(1:size(tmp_f,1),trial_idx) = tmp_f;
    else 
        error('increase the size of IDXs!')
    end
end

torque_trials = zeros(bufSize,6);
alpha_trials = zeros(bufSize,6);

torque_idx = 1;
for trial_idx = 1:size(trial,1)
    tmp_f = [force(IDX_f(IDX_f(:,trial_idx)~=0,trial_idx),1) ...
        force(IDX_f(IDX_f(:,trial_idx)~=0,trial_idx),2)];
    torque_trials(1:size(tmp_f,1),torque_idx) = tmp_f(:,1);
    torque_trials(1:size(tmp_f,1),torque_idx+1) = tmp_f(:,2);
    torque_idx = torque_idx + 2;
end

muscle_force = torque_trials;
for idx = 2:2:6
    muscle_force(:,idx) = ( torque_trials(:,idx)/2^16 ...
        * 500/5 * (2.188*5*1000)/1000 ) / moment_arm;
end

alpha_idx = 1;
for trial_idx = 1:size(trial,1)
    tmp_a = [alpha(IDX_alpha(IDX_alpha(:,trial_idx)~=0,trial_idx),1) ...
        alpha(IDX_alpha(IDX_alpha(:,trial_idx)~=0,trial_idx),2)];
    alpha_trials(1:size(tmp_a,1),alpha_idx) = tmp_a(:,1);
    alpha_trials(1:size(tmp_a,1),alpha_idx+1) = tmp_a(:,2);
    alpha_idx = alpha_idx + 2;
end

