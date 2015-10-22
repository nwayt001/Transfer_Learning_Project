%% Offline Aanalysis of Online Data
addpath('/barleyhome/nwaytowi/ARL Work/Transfer Learning Project/Matlab Code');
addpath('/barleyhome/nwaytowi/ARL Work/Transfer Learning Project/Matlab Code/MDM_SML_Functions');
addpath('D:\ARL Work\Transfer Learning Project\Matlab Code');
% Load Data
[sig state parm] = load_data();
load('ChSetKruisienski');
% x=load('18ChModels');
% trainModel = x.modelRsvp;

x=load('18ChModels_Boosted');

tmp = x.BoostedRsvpModels{1,2};
% tmp = x.NoiseBoostedModels;
for i=1:length(tmp)
    trainModel(i)=tmp{i};
end

% re-reference
refSig = mean(sig(:,[65 66]),2);
% refSig = sig(:,65);
for i=1:size(sig,2)
    sig(:,i) = sig(:,i) - refSig;
end

% Epoch data (no Latency)
prevState = 0;
currState = 0;
flashIdx = zeros(size(sig,1),1);
for i=1:size(sig,1)
    currState = state.StimulusCode(i);
    if(currState ==0 && prevState~=0)
    elseif(currState~=prevState)
        flashIdx(i) = 1;
    end
    prevState = currState;
end
length(find(flashIdx==1));
Fs=256;
% Fs = 300;
idx = find(flashIdx==1);
% Data = zeros(length(idxBio_18),256,length(find(flashIdx==1)));
for i=1:length(idx)
    Data(:,:,i) = sig(idx(i):idx(i)+Fs-1,idxBio_18)';
end

% build label vector
Labels = double(state.StimulusCode(idx));
Labels(Labels>216)=-99;
Labels(Labels~=-99)=-1;
Labels(Labels==-99)=1;

% classify each test trial with the ensemble of models
N = size(Data,3);
% scores = [];
pred_label =[];
score = zeros(N,1); 
smlThreshold=32;

% apply sml Causally
for i = 1:N
    DataB = CreateArtificialTrials(Data(:,:,i),256,0,1,31.25);
    for j=1:size(DataB,3)
        [tmpScore(:,j), tmpLabel(:,j)] = ensembleClassify(DataB(:,:,j),...
            trainModel);
    end
%     ensembleScore = mean(tmpScore,2);
    [tmp, idx] = max(abs(tmpScore),[],2);
    for k=1:length(idx)
        ensembleScore(k,1) = tmpScore(k,idx(k));
    end
    ensembleLabel = sign(ensembleScore);
    
    pred_label = [pred_label ensembleLabel];
    
    if(i>smlThreshold)
        weight = applySML(pred_label);
    else
        weight = (1/length(trainModel)) * ones(length(trainModel),1);
    end
    score(i) = weight' * ensembleLabel;
end
% apply sml (offline)
%     weight = applySML(pred_label);
% score = weight' * scores;

prediction = sign(score);
score = score';
prediction = prediction';

[PiSML] = balancedAccuracy(prediction,Labels)

PiSML_orig=PiSML;
PiSML_32 = PiSML;
PiSML_testBoostAvg = PiSML;
PiSML_testBoostENS = PiSML;
PiSML_testBoostMed = PiSML;
PiSML_testBoostMinMax = PiSML;
PiSML_testBoostMinMaxNoise = PiSML;


%% Rank Minimization Exploration

% get pred_label from above
zRank = rank(pred_label)
C2 = cond(pred_label,2);


%% compare offline with simulated online

% compare 'prediction','labels' with 'predLabel' (offline), and 'gt_labels'
% (simulated bci)
load('predLabel'); load('gt_labels');

tmp1=prediction - predLabel
length(find(tmp1~=0))
tmp2 = Labels' - gt_labels
find(tmp2~=0)

length(find(prediction==1)) 
length(find(predLabel==1))

figure; plot(prediction); hold on; plot(predLabel,'k');
