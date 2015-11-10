function out_signal = bci_Process( in_signal )
%%
% Global VARS
global bci_States modelRsvp pred_label gt_labels smlThreshold predLabel;
global previousSignal currentSignal udpSocket smlWindow Fs AllScore;
global ensembleLabel currentImage previousImage score thresholdArray pred_score;

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
    
    % data boosting
    testObs = CreateArtificialTrials(testObs,256,0,1,31.25,[]);
    for j=1:size(testObs,3)
        [tmpScore(:,j), tmpLabel(:,j)] = ensembleClassify(testObs(:,:,j),...
            modelRsvp);
    end
    [~, idx] = max(abs(tmpScore),[],2);
    for k=1:length(idx)
        ensembleScore(k,1) = tmpScore(k,idx(k));
    end
    
    pred_score = [pred_score ensembleScore];
    ensembleLabel = sign(ensembleScore);
    pred_label = [pred_label ensembleLabel];
    
    if(size(pred_label,2)>smlWindow)
        new_score = zeros(length(thresholdArray),smlWindow);
        thresh_labels=zeros(size(pred_label,1),smlWindow);
    else
        new_score = zeros(length(thresholdArray),size(pred_label,2));
        thresh_labels=zeros(size(pred_label,1),size(pred_label,2));
    end
    if(size(pred_label,2) > smlThreshold) %apply sml if enough observations
        for sub = 1:size(pred_label,1)
            for thresh = 1:length(thresholdArray)
                if(size(pred_label,2)>smlWindow)
                    new_score(thresh,:) = pred_score(sub,end-(smlWindow-1):end) - thresholdArray(thresh);
                else
                    new_score(thresh,:) = pred_score(sub,:) - thresholdArray(thresh);
                end
            end
            new_label = sign(new_score);
            try
            smlWeight = applySML(new_label);
            catch
                smlWeight = (1/length(thresholdArray)) * ones( length(thresholdArray),1 );
            end
            thresh_labels(sub,:)=sign(smlWeight'*new_label);
        end
        smlWeight = applySML(thresh_labels);
        score = smlWeight'*thresh_labels(:,end);
    else
        weight = (1/size(pred_label,1)) * ones( size(pred_label,1),1 );
        score = weight'* ensembleLabel; % <- No label refining
    end
    predLabel = [predLabel sign(score)]; % <- No label refining
    
    %% Feedback
    % UDP code - 'Prediction(T or N):ImageNumber(1-240):S:score'
    score = score+rand(1)*0.001;
    if(sign(score)>=0)
        fb = ['T' int2str(previousImage) 'S' num2str(score)];
    else
        fb = ['N' int2str(previousImage) 'S' num2str(score)];
    end
    fwrite(udpSocket,fb); % send feedback to c# application via udp
    AllScore = [AllScore score];
    % gt label array
    if(previousImage >216)
        gt_labels = [gt_labels 1];
    else
        gt_labels = [gt_labels -1];
    end
    
end

end
