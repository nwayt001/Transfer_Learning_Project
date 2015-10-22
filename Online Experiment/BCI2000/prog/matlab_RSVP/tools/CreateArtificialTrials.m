function [ S_out ] = CreateArtificialTrials(S_in,sr,UseNoise,UseTimeShift,t)
% Hubert Cecotti (2015) University of Ulster
%% Input:
% S_in : OriginalTrials = nChannels x nTimePoints x numEpochs array
% sr : sampling rate of the signal
% UseNoise = (0 or 1) flag indicating whether or not the artificial trials should include the noise deformation
% UseTimeShift = (0 or 1) flag indicating whether or not the artificial trials should include the time shift deformation
% t = the shift amount in ms
%% Output:
% S_out : Signal = nChannels x nTimePoints x numEpochs1 array
%  numEpochs1 = numEpochs * 2 if UseNoise=1 and UseTimeShift=0
%  numEpochs1 = numEpochs * 3 if UseNoise=0 and UseTimeShift=1
%  numEpochs1 = numEpochs * 6 if UseNoise=1 and UseTimeShift=1

S_out=S_in;

if UseTimeShift    
        [nChannels,nTimePoints,nEpochs]=size(S_out);
        % determine the number of sampling point that will be shifted
        % left/right
%         t=31.25; % in ms (time-shift in ms)
        TimeShift=floor(sr*t/1000);    
        S_left=S_out;
        S_right=S_out;   
        S_left(:,1+TimeShift:end,:)=S_out(:,1:nTimePoints-TimeShift,:);
        S_right(:,1:nTimePoints-TimeShift,:)=S_out(:,1+TimeShift:nTimePoints,:);   
        S_out = cat(3,S_left,S_right,S_out); % return the input signal and the shifted signals  
end

if UseNoise    
    
        [nChannels,nTimePoints,nEpochs]=size(S_out);
        % get the standard error instead of the standard deviation
        stdS=std(S_out,0,3)/sqrt(nEpochs); 
        % a random block per channel only
        Srand=2*rand(nTimePoints,nEpochs)-1;
        % it should be smoothed with a Gaussian
        nw=3;
        sigma=4;
        alpha=nw/(2*sigma);
        % Gaussian convolution
        filterg=gausswin(nw,alpha);
        tt=sum(filterg);   
        for i=1:nEpochs
            Srand(:,i)=filter(filterg,tt,Srand(:,i));
        end   
        % copy the same deformation for each filter
        Sranda=reshape(Srand,1,nTimePoints,nEpochs);
        Srand1=repmat(Sranda,nChannels,1);                
        stdS1=zeros(nChannels,nTimePoints,nEpochs);
        for i=1:nEpochs
           stdS1(:,:,i)=stdS; 
        end    
        Srand1=Srand1.*stdS1;
        S_noise=S_out+Srand1; % add the noise to the existing signal
        S_out=cat(3,S_out,S_noise); % return the input signal and the noisy signal
end
    

end

