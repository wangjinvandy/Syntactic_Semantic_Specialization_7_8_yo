function correlational_analysis
%%The within and across task correlation code
subjects=[];
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/data_info.xlsx';
if isempty(subjects)
    M=readtable(data_info);
    subjects=M.participant_id;
end
root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8';
%Tvaluefolder='extractedT_IFG_oper_anat_func_mask_topvoxels_ROIs';
%Tvaluefolder='extractedT_IFG_tri_anat_func_mask_topvoxels_ROIs';
%Tvaluefolder='extractedT_STG_anat_func_mask_topvoxels_ROIs';
Tvaluefolder='extractedT_MTG_anat_func_mask_topvoxels_ROIs';
%ROI='IFG_oper_anat_func_mask_allsentence_vs_contrl_p1_k250_adjust_mask';
%ROI='IFG_tri_anat_func_mask_allsentence_vs_contrl_p1_k250_adjust_mask';
%ROI='STG_anat_func_mask_allsentence_vs_contrl_p1_k250_adjust_mask';
ROI='MTG_anat_func_mask_allsentence_vs_contrl_p1_k250_adjust_mask';

writefile=[Tvaluefolder '_correlation1.txt'];
cd(root);
if exist(writefile)
   delete(writefile);
end
fid_w=fopen(writefile,'wt');
fprintf(fid_w,'%s %s %s %s\n', 'participant_id', 'withinGram', 'withinSCon', 'acrosstask');

for i=1:length(subjects)
    txt_run1Finite=[root '/' Tvaluefolder '/Gram_vs_PC_run1/' num2str(subjects(i)) '/' ROI '_Gram_vs_PC_run1_output.txt'];
    fid=fopen(txt_run1Finite);
    data1=textscan(fid,'%d %d %d %f');
    finiterun1=data1{4};
    txt_run2Finite=[root '/' Tvaluefolder '/Gram_vs_PC_run2/' num2str(subjects(i)) '/' ROI '_Gram_vs_PC_run2_output.txt'];
    fid2=fopen(txt_run2Finite);
    data2=textscan(fid2,'%d %d %d %f');
    finiterun2=data2{4};
    withinFinite=corrcoef(finiterun1, finiterun2);
    r_withinGram=withinFinite(1,2);
    
    txt_run1InCon=[root '/' Tvaluefolder '/SCon_vs_PC_run1/' num2str(subjects(i)) '/' ROI '_SCon_vs_PC_run1_output.txt'];
    fid3=fopen(txt_run1InCon);
    data3=textscan(fid3,'%d %d %d %f');
    inconrun1=data3{4};
    txt_run2InCon=[root '/' Tvaluefolder '/SCon_vs_PC_run2/' num2str(subjects(i)) '/' ROI '_SCon_vs_PC_run2_output.txt'];
    fid4=fopen(txt_run2InCon);
    data4=textscan(fid4,'%d %d %d %f');
    inconrun2=data4{4};
    withinInCon=corrcoef(inconrun1, inconrun2);
    r_withinSCon=withinInCon(1,2);
    
    acrosstask11=corrcoef(finiterun1, inconrun1); r_acrosstask11=acrosstask11(1,2);
    acrosstask12=corrcoef(finiterun1, inconrun2); r_acrosstask12=acrosstask12(1,2);
    acrosstask21=corrcoef(finiterun2, inconrun1); r_acrosstask21=acrosstask21(1,2);
    acrosstask22=corrcoef(finiterun2, inconrun2); r_acrosstask22=acrosstask22(1,2);
    acrosstask=mean([r_acrosstask11,r_acrosstask12,r_acrosstask21,r_acrosstask22]);
    
    fprintf(fid_w,'%d %f %f %f\n',subjects(i),r_withinGram, r_withinSCon, acrosstask); 

end 