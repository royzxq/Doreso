function runSVM_stack_final(trlist,testlist,output)
train_x = [];
train_y = [];

mfcc_dir = './data/radar/feats/mfcc/';
hpss_dir = './data/radar/feats/hm/';
lfp_dir = './data/radar/feats/lfp/';
blocksize = 128;
hopsize = 32;

validationlist = './myvalidationlist.txt';
trainlist = './mytrain.txt';
splitList(trlist,trainlist,validationlist);

f = fopen(trainlist,'r');
while ~feof(f)
    line = fgetl(f);
    line = deblank(line);
    line = regexp(line,'\t','split');
    lines = line(1);
    label = line(2);
    label = label{1};
    label = label2num(label);
    lines = lines{1};
    [path,filename,ext] = fileparts(lines);
    mfcc_name = [mfcc_dir,filename,ext,'.mat'];
    hpss_name = [hpss_dir,filename,ext,'.mat'];
    lfp_name = [lfp_dir,filename,ext,'.mat'];

    mfcc = load(mfcc_name);   
    hpss = load(hpss_name);
    lfp = load(lfp_name);

    train_tmp = [];
    for i = 1:hopsize:size(mfcc.mfcc,1)
        if i + blocksize <= size(mfcc.mfcc,1)
            temp = [mfcc.mfcc(i:i+blocksize,2:end),hpss.mfcc(i:i+blocksize,2:end)];
            dif = diff(temp);
            dif2 = diff(dif);
            m = mean(temp);
            var = std(temp);
            var_dif = std(dif);
            var_dif2 = std(dif2);
            com = [m,var,var_dif,var_dif2];
            train_tmp = [train_tmp;com];
            train_y = [train_y;label];
        end
    end
    train_x = [train_x;train_tmp,lfp.lfp_single(1:size(train_tmp,1),1:40)];
end
fclose(f);
train_x = double(train_x);
tr_m = mean(train_x);
tr_var = std(train_x);

train_x = z_score(train_x,tr_m,tr_var);

model1 = svmtrain(train_y,train_x,['-b 1']);

f = fopen(validationlist,'r');

val_y = [];
val_x = [];
while ~feof(f)
    line = fgetl(f);
    line = deblank(line);
    line = regexp(line,'\t','split');
    lines = line(1);
    label = line(2);
    label = label{1};
    label = label2num(label);
    lines = lines{1};
    [path,filename,ext] = fileparts(lines);
    mfcc_name = [mfcc_dir,filename,ext,'.mat'];
    hpss_name = [hpss_dir,filename,ext,'.mat'];
    lfp_name = [lfp_dir,filename,ext,'.mat'];

    mfcc = load(mfcc_name);   
    hpss = load(hpss_name);
    lfp = load(lfp_name);

    val_tmp = [];
    for i = 1:hopsize:size(mfcc.mfcc,1)
        if i + blocksize <= size(mfcc.mfcc,1)
            temp = [mfcc.mfcc(i:i+blocksize,2:end),hpss.mfcc(i:i+blocksize,2:end)];
            dif = diff(temp);
            dif2 = diff(dif);
            m = mean(temp);
            var = std(temp);
            var_dif = std(dif);
            var_dif2 = std(dif2);
            com = [m,var,var_dif,var_dif2];
            val_tmp = [val_tmp;com];
            val_y = [val_y;label];
        end
    end
    val_x = [val_x;val_tmp,lfp.lfp_single(1:size(val_tmp,1),1:40)];
    
end
fclose(f);
val_x = double(val_x);
val_x = z_score(val_x,tr_m,tr_var);
[~,~,prob] = svmpredict(val_y,val_x,model1,'-b 1');

prob_m = mean(prob);
prob_var = std(prob);
prob = z_score(prob,prob_m,prob_var);
model2 = svmtrain(val_y,prob);


outputfile = fopen(output,'w');
f = fopen(testlist,'r');
correct = 0 ;
while ~feof(f)
    line = fgetl(f);
    line = deblank(line);
    line = regexp(line,'\t','split');
    lines = line(1);
    lines = lines{1};
    [path,filename,ext] = fileparts(lines);

    mfcc_name = [mfcc_dir,filename,ext,'.mat'];
    hpss_name = [hpss_dir,filename,ext,'.mat'];
    lfp_name = [lfp_dir,filename,ext,'.mat'];

    mfcc = load(mfcc_name);
    hpss = load(hpss_name);
    lfp = load(lfp_name);

    test_input = [];
    len = size(mfcc.mfcc,1);
    for i = 1:hopsize:len
        if i + blocksize  <= len
            temp = [mfcc.mfcc(i:i+blocksize,2:end),hpss.mfcc(i:i+blocksize,2:end)];
            dif = diff(temp);
            dif2 = diff(dif);
            m = mean(temp);
            var = std(temp);
            var_dif = std(dif);
            var_dif2 = std(dif2);
            com = [m,var,var_dif,var_dif2];
            test_input = [test_input;com];
        end
    end
    test_input = [test_input,lfp.lfp_single(1:size(test_input,1),1:40)];
    test_input = double(test_input);
    test_input = z_score(test_input,tr_m,tr_var);
    [~,~,prob] = svmpredict(ones(size(test_input,1),1),test_input,model1,'-b 1');
    prob = z_score(prob,prob_m,prob_var);
    predict = svmpredict(ones(size(test_input,1),1),prob,model2);
    
    prediction = num2label(mode(predict));
    fprintf(outputfile,'%s\t%s\n',lines,prediction);
end
fclose(outputfile);
fclose(f);

end



