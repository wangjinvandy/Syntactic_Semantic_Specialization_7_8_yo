%% This script will be used for the first time screening of the data (only give you movement info)
%This script was created by Professor Baxter Rogeres (VUIIS), but is heavily modified based on our lab pipeline by Jin Wang 3/7/2019
%(1) realignment to mean, reslice the mean.
%(5) Art_global. It calls the realignmentfile (the rp_*.txt) to do the interpolation. This step identifies the bad volumes(by setting scan-to-scan movement
%    mv_thresh =1.5mm and global signal intensity deviation Percent_thresh= 4 percent, any volumes movement to reference volume, which is the mean, >5mm) and repair
%    them with interpolation. This step uses art-repair art_global.m function (the subfunctions within it are art_repairvol, which does repairment, and art_climvmnt, which identifies volumes movment to reference.



global CCN;
addpath(genpath('/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/scripts')); %This is the code path
spm_path='/dors/booth/JBooth-Lab/BDL/LabCode/typical_data_analysis/spm12_elp'; %This is your spm path
addpath(genpath(spm_path));
root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8'; %This is your project folder
subjects=[];
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/all_subjects.xlsx';
if isempty(subjects)
    M=readtable(data_info);
   subjects=M.subjects;
end

CCN.preprocessed_folder='raw'; %This is your data folder needs to be preprocessed
CCN.session='ses-7'; %This is the time point you want to analyze. If you have two time points, do the preprocessing one time point at a time by changing ses-T1 to ses-T2.
CCN.func_folder='sub*'; % This is your functional folder name
CCN.func_pattern='sub*.nii'; %This is your functional data name
%CCN.anat_pattern='ses-T1_T1w*.nii'; %This is your anat data name


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%shouldn't be modified below%%%%%%%%%%%%%%%
% Initialize
%addpath(spm_path);
spm('defaults','fmri');
spm_jobman('initcfg');
spm_figure('Create','Graphics','Graphics');

% Dependency and sanity checks
if verLessThan('matlab','R2013a')
    error('Matlab version is %s but R2013a or higher is required',version)
end

req_spm_ver = 'SPM12 (6225)';
spm_ver = spm('version');
if ~strcmp( spm_ver,req_spm_ver )
    error('SPM version is %s but %s is required',spm_ver,req_spm_ver)
end
try
    %Start to preprocess data from here
    for i=1:length(subjects)
        fprintf('work on subject %s\n', num2str(subjects(i)));
        CCN.subj_folder=[root '/' CCN.preprocessed_folder '/sub-' num2str(subjects(i))];
        out_path=[CCN.subj_folder '/' CCN.session];
        CCN.func_f='[subj_folder]/[session]/func/[func_folder]/';
        func_f=expand_path(CCN.func_f);
        func_file=[];
        for m=1:length(func_f)
            func_file{m}=expand_path([func_f{m} '[func_pattern]']);
        end
        
        
        Percent_thresh= 4; %global signal intensity change
        mv_thresh =1.5; % scan-to-scan movement
        MVMTTHRESHOLD=5; % movement to reference,see in art_clipmvmt
        
        %expand 4d functional data to 3d data
        for x=1:length(func_file)
            [rfunc_file, rp_file] = realignment_byrun_4d(char(func_file{x}), out_path);%this will run the realignment by run by run
            [func_p,func_n,func_e] = fileparts(rfunc_file);
            swfunc_file=rfunc_file;
            swfunc_vols = cellstr(spm_select('ExtFPList',func_p,['^' func_n func_e '$'],inf));
            art_global_jin(char(swfunc_vols),rp_file,4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
            [p,n,ext]=fileparts(swfunc_file);
            delete([p '/v' n ext]);
            delete([p '/mean' n ext]);
            delete([p '/rp_' n '.txt']);
            delete([p,'/' n,'.mat']);
        end
        outputfig1=[out_path '/func/artglobal*jpg'];
        system(['rm ' outputfig1])
        outputfig2=[out_path '/realignment*.png'];
        system(['rm ' outputfig2])
    end
catch e
    rethrow(e)
    %display the errors
end
