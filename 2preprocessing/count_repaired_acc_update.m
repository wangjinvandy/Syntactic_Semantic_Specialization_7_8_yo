%%
%count_repaired
%This script calculate the movement, accuracy, and rt for each run. written
%by Jin Wang 1/3/2021
%The number of volumes being replaced (the second column) and how many chunks of more than 6 consecutive volumes being
%replaced (the third column) are based on the output of art-repair (in the code main_just_for_movement.m). 
%The acc and rt for each condition of a run are calculated based on the
%documented in ELP/bids/derivatives/func_mv_acc_rt/ELP_Acc_RT.doc

global CCN;
root='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/raw';
addpath(genpath('/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/scripts'));
CCN.func_n='sub*Gram*';
CCN.ses='ses-7';
n=6; %number of consecutive volumes being replaced. no more than 6 consecutive volumes being repaired.
writefile='mv_acc_Gram_behavior_ses-7.txt';
subjects = []; % if this is empty, it will read data_info.
data_info='/gpfs51/dors2/gpc/JamesBooth/JBooth-Lab/BDL/jinwang/PlausGram_JW_7-8/all_subjects.xlsx';
bids_folder='/dors/booth/JBooth-Lab/BDL/ELP/bids';
if isempty(subjects)
    M=readtable(data_info);
    subjects=M.subjects;
end

%%%%%%%%%%%%%%should not edit below%%%%%%%%%%%%%%%%%%%%%%
cd(root);
if exist(writefile)
    delete(writefile);
end
fid=fopen(writefile,'w');
hdr='subjects run_name acq_date num_repaired chunks cond1 acc1 rt1 cond2 acc2 rt2 cond3 acc3 rt3 cond4 acc4 rt4';
fprintf(fid, '%s', hdr);
fprintf(fid, '\n');
for i=1:length(subjects)
    func_p=[root '/sub-' num2str(subjects(i))];
    func_f=expand_path([func_p '/[ses]/func/[func_n]/']);
    for j=1:length(func_f)
        run_n=func_f{j}(1:end-1);
        [run_p, run_name]=fileparts(run_n);
        %get the movement data from art_repair
        cd(run_n);
        fileid=fopen('art_repaired.txt');
        m=fscanf(fileid, '%f');
        [num_repaired, col]=size(m);
        N=n; %N=(n-1); it is no more than 6 consecutive volumes repaired described in the paper. This is wrong, corrected by Jin 6/21/2020
        x=diff(m')==1;
        ii=strfind([0 x 0], [0 1]);
        jj=strfind([0 x 0], [1 0]);
        %idx=max(jj-ii);
        %out=(idx>=N);
        out=((jj-ii)>=N);
        if out==0
            chunks=0;
        else
            %chunks=length(out); This is wrong. corrected on 5/1/2020 by
            %Jin Wang
            chunks=sum(out(:)==1);
        end
        
        %get accuracies and rt from events.tsv
        run_name_e=run_name(1:end-4);
        datafile=[bids_folder '/sub-' num2str(subjects(i)) '/' CCN.ses '/func/' run_name_e 'events.tsv'];
        data=tdfread(datafile);
        conditions=unique(data.trial_type,'row');
        acc_by_condition=[];
        rt_by_condition=[];
        rt_allvalue=[];
        rt_all_correcttrials=data.calculated_RT(data.calculated_accuracy==1, :);
        for jj=1: size(rt_all_correcttrials,1)
            if ~contains(num2str(rt_all_correcttrials(jj,:)), 'n/a')
                if isa(rt_all_correcttrials(jj,:),'double')
                    rt_allvalue=[rt_allvalue; rt_all_correcttrials(jj,:)];
                else
                    rt_allvalue=[rt_allvalue; str2double(rt_all_correcttrials(jj,:))];
                end
            end
        end
        M=mean(rt_allvalue);
        SD3=3*std(rt_allvalue);
        min1=M-SD3;
        min2=0.25;
        mini=max([min1; min2]);
        maxi=M+SD3;
        for ii=1:size(conditions,1)
            [~, lencond]=size(conditions); %corrected 12/18/2020.
            thiscondition=conditions(ii,:);
            acc_thiscond=data.calculated_accuracy((sum((data.trial_type==thiscondition)')==lencond)');
            rt_thiscond=data.calculated_RT(((sum((data.trial_type==thiscondition)')==lencond)'),:);
            
            rt_thiscond_new_count=0;
            rt_thiscond_new_value=[];
            for mm=1: size(rt_thiscond,1)
                if ischar(rt_thiscond(mm,:)) && ~contains(rt_thiscond(mm,:),'n/a')
                    cur_rt=str2double(rt_thiscond(mm,:));
                    if acc_thiscond(mm)==1 && cur_rt>mini && cur_rt<maxi
                        rt_thiscond_new_count=rt_thiscond_new_count+1;
                        rt_thiscond_new_value=[rt_thiscond_new_value; cur_rt];
                    end
                elseif ~ischar(rt_thiscond(mm,:))
                    cur_rt=rt_thiscond(mm,:);
                    if acc_thiscond(mm)==1 && cur_rt>mini && cur_rt<maxi
                        rt_thiscond_new_count=rt_thiscond_new_count+1;
                        rt_thiscond_new_value=[rt_thiscond_new_value; cur_rt];
                    end
                end
                
            end
            average_rt=sum(rt_thiscond_new_value)/rt_thiscond_new_count;
            average_acc=sum(acc_thiscond)/size(acc_thiscond,1);
            acc_by_condition=[acc_by_condition; average_acc];
            rt_by_condition=[rt_by_condition; average_rt];
        end
        
        %get the shifted dates of acquisition date for each run
        fname=[bids_folder '/sub-' num2str(subjects(i)) '/' CCN.ses '/func/' run_name '.json'];
        if exist(fname)
            val=jsondecode(fileread(fname));
            shifted_data_acq=val.ShiftedAquisitionDate;
        else
            shifted_data_acq='NaN';
        end
        
        %save all the values to txt
        fprintf(fid,'%s %s %s %d %d %s %.4f %.6f %s %.4f %.6f %s %.4f %.6f %s %.4f %.6f\n', ...
            num2str(subjects(i)), run_name, shifted_data_acq, num_repaired, chunks, conditions(1,:), acc_by_condition(1,:), rt_by_condition(1,:), ...
            conditions(2,:), acc_by_condition(2,:), rt_by_condition(2,:), conditions(3,:), acc_by_condition(3,:), rt_by_condition(3,:),...
            conditions(4,:), acc_by_condition(4,:), rt_by_condition(4,:));
    end
end





    end
end




