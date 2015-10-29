function out_signal = bci_Process( in_signal )

% Global VARS
global bci_States modelRsvp pred_label gt_labels smlThreshold predLabel;
global previousSignal currentSignal udpSocket;
global ensembleLabel currentImage previousImage score;

% do a two-block buffer of signal and image state
out_signal=in_signal;

if(size(in_signal,1)>18)
    avgSig = mean(in_signal([end-1 end],:),1);
    in_signal  = in_signal - repmat(avgSig,size(in_signal,1),1);
    in_signal = in_signal(1:end-2,:);
end

previousSignal = currentSignal;
currentSignal = in_signal;

previousImage = currentImage;
currentImage = bci_States.StimulusCode;

% Classify if prevImage does not equal zero. We classify on the 
% previous image by using the signal from the previous block 
% coresponding to a half second ago concatonated with the current block
if(previousImage~=0) % classify
    testObs = [previousSignal currentSignal]; % concatonate previous and current blocks
     
%     [~, ensembleLabel] = ensembleClassify(testObs,modelRsvp);
%%-----------------------START---------------------------------------%%
    testObs = CreateArtificialTrials(testObs,256,0,1,31.25);
    for j=1:size(testObs,3)
        [tmpScore(:,j), tmpLabel(:,j)] = ensembleClassify(testObs(:,:,j),...
            modelRsvp);
    end
    [~, idx] = max(abs(tmpScore),[],2);
    for k=1:length(idx)
        ensembleScore(k,1) = tmpScore(k,idx(k));
    end
    ensembleLabel = sign(ensembleScore);
    
    pred_label = [pred_label ensembleLabel];
    
    if(size(pred_label,2) > smlThreshold) %apply sml if enough observations
         if(size(pred_label,2)>200)
             smlWeight = applySML(pred_label(:,end-199:end));
         else
            smlWeight = applySML(pred_label);
         end
%         score = smlWeight'* pred_label; % <- label refining
        score = smlWeight'* ensembleLabel; % <- No label refining
    else
        weight = (1/size(pred_label,1)) * ones( size(pred_label,1),1 );
%         score = weight'* pred_label; % <- label refining
        score = weight'* ensembleLabel; % <- No label refining
    end
%     predLabel = sign(score); % <- label refining
    predLabel = [predLabel sign(score)]; % <- No label refining
    
    %%-----------------------END---------------------------------------%%
    
    % UDP feedback (images 217 -240 are targets, all else are
    % non-targets)
    % UDP code - 'Prediction(T or N):ImageNumber(1-240):S:score'
    if(sign(score)>=0)
        fb = ['T' int2str(previousImage) 'S' num2str(score)];
    else
        fb = ['N' int2str(previousImage) 'S' num2str(score)];
    end
    fwrite(udpSocket,fb); % send feedback to c# application via udp

    % gt label array
    if(previousImage >216)
        gt_labels = [gt_labels 1];
    else
        gt_labels = [gt_labels -1];
    end
    
end

end
