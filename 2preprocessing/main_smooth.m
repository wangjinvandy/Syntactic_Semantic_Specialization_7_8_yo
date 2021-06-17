%%
%This script was created by Professor Baxter Rogeres (VUIIS), but is heavily modified based on our lab pipeline by Jin Wang 3/7/2019
%(1) realignment to mean, reslice the mean.
%(2) segment anatomical image to TPM template. We get a deformation file "y_filename" and this is used in normalisation step to normalize all the
%    functional data and the mean functional data.
%(3) Then we make a skull-striped anatomical T1 (based on segmentation) and coregister mean functional data (and all other functional data) to the anatomical T1.
%(4) Smoothing.
%(5) Art_global. It calls the realignmentfile (the rp_*.txt) to do the interpolation. This step identifies the bad volumes(by setting scan-to-scan movement
%    mv_thresh =1.5mm and global signal intensity deviation Percent_thresh= 4 percent, any volumes movement to reference volume, which is the mean, >5mm) and repair
%    them with interpolation. This step uses art-repair art_global.m function (the subfunctions within it are art_repairvol, which does repairment, and art_climvmnt, which identifies volumes movment to reference.
%(6) We use check_reg.m to see how well the meanfunctional data was normalized to template by visual check.
%(7) collapse all the 3d files into 4d files for saving space. You can decide whether you want to delete the product of not later.
%Before you run this script, you should make sure that your data structure is as expected.


global CCN;
addpath(genpath('//gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/scripts')); %This is the code path
spm_path='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/LabCode/typical_data_analysis/spm12_elp'; %This is your spm path
tpm='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/LabCode/typical_data_analysis/templates_cerebroMatic/ELP_55_8Template/mw_com_prior_Age_0081.nii'; %This is your template path
addpath(genpath(spm_path));
root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8'; %This is your project folder
subjects=[];
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/data_info.xlsx'; %final_sample sheet
if isempty(subjects)
    M=readtable(data_info);
    subjects=M.participant_id;
end

% test_subjects={}; 
% run_script=1; % 1 is to run test_subjects, 2 is to run all the rest of the subjects in the preprocessed folder that's not specified in test_subjects. 
CCN.preprocessed_folder='preproc'; %'raw'; %This is your data folder needs to be preprocessed
CCN.func_folder='sub*'; % This is your functional folder name
output_fig='output_figures'; %this will put your output figures into output_figures folder under the specified session
CCN.func_pattern='wsub*.nii'; %This is your functional data name
CCN.anat_pattern='sub*_T1w*.nii'; %This is your anat data name
CCN.session='ses-7';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%shouldn't be modified below%%%%%%%%%%%%%%%
%if user did not specify the subjects list, then it will read in all the data in bids
% listing=dir([root '/' CCN.preprocessed_folder]);
% all_list=extractfield(listing,'name');
% index=strfind(all_list,'sub');
% idx=find(not(cellfun('isempty',index)));
% subjects_all=all_list(idx);
% if run_script ==1
%     subjects=test_subjects;
% else
%     subjects=subjects_all(~ismember(subjects_all,test_subjects));
% end
        

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
    for i=92:length(subjects)
        fprintf('work on subject %s\n', num2str(subjects(i)));
        CCN.subj_folder=[root '/' CCN.preprocessed_folder '/sub-' num2str(subjects(i))];
        out_path=[CCN.subj_folder '/' output_fig];
        if ~exist(out_path)
            mkdir(out_path)
        end
        CCN.func_f='[subj_folder]/[session]/func/[func_folder]/';
        func_f=expand_path(CCN.func_f);
        func_files=[];
        for m=1:length(func_f)
            func_files{m}=expand_path([func_f{m} '[func_pattern]']);
        end
        CCN.anat='[subj_folder]/[session]/anat/[anat_pattern]';
        anat_file=char(expand_path(CCN.anat));
        

        
        % Spatial smoothing
        fwhm=6;
        swfunc_file = smoothing_4d(func_files,fwhm);
        
        %Art_global (identify bad volumes and repair them using interpolation), it
        %will add a v to the files. In this art_global_jin, the
        %art_clipmvmt is the movement of all images to reference.
        Percent_thresh= 4; %global signal intensity change
        mv_thresh =1.5; % scan-to-scan movement
        MVMTTHRESHOLD=5; % movement to reference,see in art_clipmvmt
        
        for ii=1:length(swfunc_file)
            [swfunc_p,swfunc_n,swfunc_e] = fileparts(char(swfunc_file{ii}));
            swfunc_vols=cellstr(spm_select('ExtFPList',swfunc_p,['^' swfunc_n swfunc_e '$'],inf));
            %art_global_jin(char(swfunc_vols),rp_file{ii},4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
            rp_file=[swfunc_p, '/rp_', swfunc_n(5:end) '.txt'];
            art_global_jin(char(swfunc_vols),rp_file,4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
        end
        
        % Coreg check
      %  coreg_check(wmeanfunc, out_path, tpm);
        
    end
catch e
    rethrow(e)
    %display the errors
end
    %art_global_jin(char(swfunc_vols),rp_file{ii},4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
            rp_file=[swfunc_p, '/rp_', swfunc_n(5:end) '.txt'];
            art_global_jin(char(swfunc_vols),rp_file,4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
        end
        
        % Coreg check
      %  coreg_check(wmeanfunc, out_path, tpm);
        
    end
catch e
    rethrow(e)
    %display the errors
end
