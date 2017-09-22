% read in raw data and store forces & EMG data
clear
clc

disp(' ')
disp('********************************************************************')
disp('********************************************************************')
disp('PROCESS EMG AND FORCE SIGNALS AS PART OF MUTA 2017 PROJECT')
disp('REQUIRES INPUT DATA: PROCESS EMG AND FORCE SIGNALS USING SCRIPT')
disp('"rename_data_files_from_leo.m". ORIGINAL DATA IS PROCESSED BY L.GIZZI')
disp('HARNOOR SAINI 2017')
disp('********************************************************************')
disp(' ')
%--- characterisation properties
max_EMG_voltage = 85.5026;
moment_arm = 0.21;


prompt='Which case to process? (isotonic, ramp, MVC, other): ';
case_type = input(prompt, 's');

%prompt='How many trials to process: ';
%num_trials = input(prompt);
num_trials = 3;

prompt='Attempt to auto detect trials? (DO NOT USE FOR RAMP) (1=yes, 0=defaults): ';
auto_detect_trialsLims = input(prompt);

check_indv = 1;
if auto_detect_trialsLims == 1
    prompt='Check each trial auto-fit? (1=yes, 0=no): ';
    check_indv = input(prompt);
end

disp(['Maximum EMG voltage, at which alpha is defined to be 1, is: ' ...
    num2str(max_EMG_voltage)])
disp(['Moment arm, by which the muscle force is computed from the measured torque , is: ' ...
    num2str(moment_arm)])
disp(' ')

%--- get list of all files in 'data' folder
files = dir('data/*.mat');

ramp_idx = 1;
isotonic_idx = 1;
MVC_idx = 1;
other_idx = 1;
for file_idx = 1:size(files,1)
   if strfind(files(file_idx).name,'amp')
      ramp_IDs(ramp_idx) = file_idx;
      ramp_idx = ramp_idx + 1;
   elseif strfind(files(file_idx).name,'sotonic')
      isotonic_IDs(isotonic_idx) = file_idx;
      isotonic_idx = isotonic_idx + 1;
   elseif strfind(files(file_idx).name,'lexion')
      MVC_IDs(MVC_idx) = file_idx;
      MVC_idx = MVC_idx + 1;
   else 
      other_IDs(other_idx) = file_idx;
      other_idx = other_idx + 1;
   end   
end

if strcmp(case_type, 'isotonic')
   	CASE_ID = isotonic_IDs;
elseif strcmp(case_type, 'ramp')
    CASE_ID = ramp_IDs;
elseif strcmp(case_type,'MVC')
    CASE_ID = MVC_IDs;
elseif strcmp(case_type,'other')
    CASE_ID = other_IDs;
end

%--- load data file
cont = 'yes';
for file_idx = CASE_ID
    disp('-------------------------------------------------------------------')
    disp(['PROCESSING FILE: ' files(file_idx).name '...' ])
    disp(' ')   
    [pathstr,name,ext] = fileparts(files(file_idx).name);
    
    filespath = ['data/' files(file_idx).name];
    % store setup name
    setup = files(file_idx).name;
    load(filespath);

    %--- extract force & EMG data
    force = results.force.RMS';
    EMG = results.EMG.TA.RMS.average;
    
    %--- covert from samples to time 
    sample_tstep = 0.2495; %seconds per sample 
    disp('-------------------------------------------------------------------')
    disp(['TIME CONTROLLED BY SEC/SAMPLE: ' num2str(sample_tstep)])
    disp(' ')
    
    % time span
    tmpSize = length(EMG);
    tvec(tmpSize,1) = zeros;
    tvec(1,1) = 0;
    for i = 2:tmpSize
        tvec(i,1) = i*sample_tstep;
    end

    % add in time span
    force = [tvec force];
    EMG = [tvec EMG-min(EMG)];

    f = figure('visible', 'on');
    plot(EMG(:,1),EMG(:,2))
    xlabel('samples (-)')
    ylabel('average EMG (V)')    
    
    %--- split trials for output in seconds
    if auto_detect_trialsLims == 1
        findchangepts(EMG(:,2),'MaxNumChanges',num_trials*2,'Statistic','linear');
        change_idx = 1;
        detected_changes = findchangepts(EMG(:,2),'MaxNumChanges',num_trials*2,'Statistic','linear');
        %detected_changes = [0;detected_changes];
        for trial_idx = 1:num_trials
            trial(trial_idx,1) = detected_changes(change_idx)*sample_tstep;
            trial(trial_idx,2) = detected_changes(change_idx+1)*sample_tstep;
            change_idx = change_idx + 2;
        end
        if check_indv == 1
            prompt = 'Does the auto detect (green lines) look ok?: (no to stop):  ';
            cont = input(prompt, 's');
        else 
            cont = 1;
        end
    else   
        trial(1,:) = [0 30]; 
        trial(2,:) = [50 80];
        trial(3,:) = [100 130];
    end
    
    if strcmp(cont,'no')
        error('Auto-detect sucks! OR you used ir for ramp!')
    end
    
    
    %--- saving figures 
    plotname = ['figures/' name '_' 'EMG.png'];    
    saveas(gcf,plotname)  
    close(f)
    
    bufSize = 1000; 
    [alpha,muscle_force, EMG] = ...
        process_signals(force, EMG, trial,bufSize,max_EMG_voltage,moment_arm,sample_tstep);
    
    %--- store in structures & remove all zero values introduced by buffer
    alpha_struct{1,num_trials}=zeros;
    force_struct{1,num_trials}=zeros;

    struct_idx = 1;
    for trial_idx = 1:2:num_trials*2
        alpha_struct{struct_idx} = [alpha(alpha(:,trial_idx)~=0, trial_idx) ...
            alpha(alpha(:,trial_idx)~=0,trial_idx+1)];
        force_struct{struct_idx} = [muscle_force(muscle_force(:,trial_idx)~=0, trial_idx) ...
            muscle_force(muscle_force(:,trial_idx)~=0,trial_idx+1)];
        struct_idx = struct_idx+1;
    end

    %--- average of trials
    [alpha_avg] = average_trials(alpha_struct,num_trials,bufSize);
    [force_avg] = average_trials(force_struct,num_trials,bufSize);

    %--- plotting
    f = figure('visible', 'off');
    for plot_idx = 2:2:6
        c = [0.5 0.5 0.5];
        scatter(alpha(:,plot_idx),muscle_force(:,plot_idx),[],c,'x')
        hold on
    end
    minSize = min([size(alpha_avg,1) size(force_avg,1)]);
    scatter(alpha_avg(1:minSize,2),force_avg(1:minSize,2),'r')
    
    xlabel('alpha (-)')
    ylabel('muscle force (N)')
    title(name)
    %-- line of best fit - intercept is @ 0,0!
    x = alpha_avg(1:minSize,2);
    y = force_avg(1:minSize,2);
    a = x(:)\y(:);
    plot(x,a*x, '-r')
    axis([0 inf 0 inf])
    dim = [.2 .6 .3 .3];
    str = ['Coefficent of alpha-to-force is: ' num2str(a) ];
    annotation('textbox',dim,'String',str,'FitBoxToText','on');
    
    order = 1;
    polynom_fit = 0;
    if polynom_fit == 1
        p = polyfit(x,y,order);
        f = polyval(p,x);
        hold on
        plot(x,f,'b')
    end
    
    %--- saving figures
    disp('Saving figures...')
    disp(' ')
    plotname = ['figures/' name '_' 'alpha_v_force.eps'];
    saveas(gcf,plotname,'epsc')
    plotname = ['figures/' name '_' 'alpha_v_force.png'];
    saveas(gcf,plotname)
    
    f = figure('visible', 'off');
    for trial_idx = 1:num_trials
        scatter(alpha_struct{trial_idx}(:,1)-alpha_struct{trial_idx}(1,1) ...
            ,alpha_struct{trial_idx}(:,2), [], c)
        hold on
    end
    plot(alpha_avg(:,1),alpha_avg(:,2), 'r')
    title(name)
    xlabel('time (s)')
    ylabel('alpha (-)')
    
    %--- saving figures
    plotname = ['figures/' name '_' 'alpha.png'];
    saveas(gcf,plotname)
    
    f = figure('visible', 'off');
    for trial_idx = 1:num_trials
        scatter(force_struct{trial_idx}(:,1)-force_struct{trial_idx}(1,1) ...
            ,force_struct{trial_idx}(:,2), [], c)
        hold on
    end
    plot(force_avg(:,1),force_avg(:,2), 'r')
    title(name)
    xlabel('time (s)')
    ylabel('force (-)')
    
    %--- saving figures
    plotname = ['figures/' name '_' 'force.png'];
    saveas(gcf,plotname)
    
    
    % -- clearing variables 
    disp('Clearing variables from last run...')
    clear force
    clear EMG
    clear tvec
    
    fID = fopen('output/mean_vals.txt','a');
    format = '%s, %f, %f \n';
    fprintf(fID,format,name,mean(alpha_avg(:,2)),mean(force_avg(:,2)));
    fclose(fID);
    
    %--- write out activation files (to be read in by VUMAT)
    %disp(['Writing out files'])
    %disp ' '

    %alpha_t1 = [(alpha(I1,1)-alpha(I1(1),1)) alpha(I1,2)];
    %outname = ['output/alpha_' setup '_t1' '.txt'];
    %dlmwrite(outname,alpha_t1,'delimiter','\t');

    %alpha_t2 = [(alpha(I2,1)-alpha(I2(1),1)) alpha(I2,2)];
    %outname = ['output/alpha_' setup '_t2' '.txt'];
    %dlmwrite(outname,alpha_t2,'delimiter','\t');

    %alpha_t3 = [(alpha(I3,1)-alpha(I3(1),1)) alpha(I3,2)];
    %outname = ['output/alpha_' setup '_t3' '.txt'];
    %dlmwrite(outname,alpha_t3,'delimiter','\t');
    close all 
end
    
disp(['Complete'])
disp ' '