%%% Script to run 3dFMHMx over loop of subjects. It will display the average values from the subjects at the end.
%%% You can also choose to write out the values for each subject into a
%%% text file. The last line will be the average values. You can also
%%% choose to run 3dclustsim directly from this script and the average
%%% values will be automatically entered in. 
%%Created by : Jessica Younger 7/9/16 



addpath(genpath('/dors/booth/JBooth-Lab/BDL/LabCode/typical_data_analysis/spm12_elp'));
%addpath(genpath('/dors/gpc/JamesBooth/JBooth-Lab/BDL/fmriTools'));

spm_defaults;
spm('defaults','fmri');

% make sure the scriptdir is in the path
addpath(pwd);

% What directory has all your subject folders? We assume that in each subject folder is
% a folder containing the SPM.mat file for that subject's 1st level analysis
rootDIR  = '/dors/booth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/preproc';

%What directory holds the model file for each subject
modelDIR  = 'analysis_smooth/deweight';

%List your subjects 
namesubjects={}; % if not filled in, the data_info1.xlsx will be read in
data_info='/dors/booth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/sub76sample.xlsx';

%3dcluststim options
threedclust=1; %Run 3dclustsim with results? 1 for yes, 0 for no
pthr = [.005 .001]; %enter values for pthr .05 .01
ROI = '/dors/booth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/ROIs/wholebrainmask.nii'; %onsetrhyme_vs_perc_VS_weakstrong_vs_perc/wholebrainmask.hdr'; %pathway to your ROI

%Writing options to have the matrix of ACF values for each subject written
%out. The last lnie will be the average values to use in 3dclustsim
write=1; %write the individual subject information? 1 yes 0 no
writeDIR  = rootDIR; % Where do you want the text file  to be written?
filename = 'analysis_3dclust_wholebrain';

%%%%%Do not edit below this line%%%%
if isempty(namesubjects)
    M=readtable(data_info);
    namesubjects=M.participant_id;
end


numsubjects = length(namesubjects);
C=zeros(numsubjects,3);
idx = 1;
subj = 1:numsubjects;
 for x = subj
    swd = [rootDIR filesep 'sub-' num2str(namesubjects(x)) filesep modelDIR];
    %change to the subjects directory
    cd(swd);
    %run 3dFWHMx and store values
    diary('output.txt')
    %system(['3dFWHMx -detrend -ACF -mask mask.hdr -input ResMS.hdr -out
    %temp']); %Jin changed it here to make it compatable with
    %spm12. 5/3/2019
    system(['3dFWHMx -detrend -ACF -mask mask.nii -input ResMS.nii -out temp']);
    diary off
    temp1=textread('output.txt', '%s', 'delimiter', '\n');
    temp2=temp1(13,1);
    temp2=char(temp2);%     C(idx,1) = str2num(temp2(1:8));
%     C(idx,2) = str2num(temp2(10:17));
%     C(idx,3) = str2num(temp2(19:25));
    temp3=strsplit(temp2); %Jin changed here to make it easier to recognize the values
    C(idx,1) = str2num(temp3{1});
    C(idx,2) = str2num(temp3{2});
    C(idx,3) = str2num(temp3{3}); 
    idx = idx+1;
 end
 
 %Get mean ACF values
avgA = mean(C(:,1));
avgC = mean(C(:,2));
avgF = mean(C(:,3));
 
C(1+numsubjects, :) = [avgA, avgC, avgF];

if write==1
    fextension='.txt';
    cd(writeDIR);
    writefile=char([char(filename) char(fextension)]);
    dlmwrite(writefile, C, 'delimiter', '\t', '-append');
 end
diary 3dClustSim_Tables_wholebrainmask
if threedclust==1
system(['3dClustSim -pthr ' num2str(pthr) ' -mask ' ROI ' -ACF ' num2str(avgA) ' ' num2str(avgC) ' ' num2str(avgF)]);
end

Values=[avgA, avgC, avgF];
display(Values)
diary off
