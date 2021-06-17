%%
% This is the code for copying data from ELP bids
% written by Jin Wang 5/27/2020


root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/ELP/bids';  %This is the path where the data raw data sits
subjects=[]; % you can either manually put in your subjects or leave it empty and define a path of an excel that contains subject numbers as indicated below. 
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/all_subjects.xlsx'; 
%In this excel, there should be a column of subjects with the header
%(subjects). The subjects should all be numbers (e.g. 5002, not sub-5002).
if isempty(subjects)
    M=readtable(data_info);
   subjects=M.participant_id;
end

new_root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/preproc'; %This is the folder path where you want to do analysis
system(['chmod -R 770 ', new_root]);
addpath(genpath('/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/scripts')); %make sure you copied the code expand_path.m in your codes
global CCN;
CCN.funcf1='sub*Plaus*bold.nii.gz'; %This is the functional folder you want to copy. In this example, it's just Plaus and Gram.
CCN.funcf2='sub*Gram*bold.nii.gz';
CCN.anat='*_T1w.nii.gz'; % This is the file name of your anatomical data
session='ses-7'; % This is the session. You can define 'ses*' to grab all sessions too. In this example, it's just grabbing ses-7.

%%%%%%%%%%%%%%%%%%typically do not modify anything below unless necessary%%%%%%%%%%%%%%%%%
%create a multiple_t1.txt, if there is an existing one, delete it. 
cd(new_root);

for i= 1:length(subjects)
    old_dir=[root '/sub-' num2str(subjects(i)) '/' session];
    new_dir=[new_root '/sub-' num2str(subjects(i)) '/' session];
    if ~isempty(expand_path([old_dir '/func/' '[funcf1]'])) && ~isempty(expand_path([old_dir '/func/' '[funcf2]'])) %This line should modified if your wanted files are not two as in my example.
        if ~exist(new_dir)
            mkdir(new_dir);
            mkdir([new_dir '/func']);
            mkdir([new_dir '/anat']);
        end
        source{1}=expand_path([old_dir '/func/[funcf1]']); source{2}=expand_path([old_dir '/func/[funcf2]']);%This line should modified if your wanted files are not two as in my example.
        for j=1:length(source)
            for jj=1:length(source{j})
                [f_path, f_name, ext]=fileparts(source{j}{jj});
                %e_name=[f_name(1:end-8) 'events.tsv'];
                mkdir([new_dir '/func/' f_name(1:end-4)]);
                dest=[new_dir '/func/' f_name(1:end-4) '/' f_name ext];
                %dest_event=[new_dir '/func/' f_name(1:end-4) '/' e_name];
                %dest_json=[new_dir '/func/' f_name(1:end-4) '/' f_name(1:end-4) '.json'];
                copyfile(source{j}{jj},dest);
                system(['chmod 770 ', dest]);
                gunzip(dest);
                delete(dest);
                %copyfile([f_path '/' e_name],dest_event);
                %copyfile([f_path '/' f_name(1:end-4) '.json'], dest_json);
            end
        end
        
        sanat=expand_path([old_dir '/anat/[anat]']);
        for k=1:length(sanat)
            [a_path, a_name, ext]=fileparts(sanat{k});
            dt=[new_dir '/anat/' a_name ext];
            copyfile(sanat{k},dt);
            system(['chmod 770 ', dt]);
            gunzip(dt);
            delete(dt);
        end
    else
        fprintf('%s targeted tasks not found\n', num2str(subjects(i))); % in the command window, it will print out the subjects that you requested but not found in bids.
    end
end
system(['chmod -R 770 ', new_root]);


