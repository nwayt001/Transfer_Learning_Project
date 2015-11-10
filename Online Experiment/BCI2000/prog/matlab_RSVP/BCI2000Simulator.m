% BCI 2000 Simulator
% this program simulates bci2000 for online experimental debuggin

%% load in pilot data (data previously collected using bci2000).
% for i=1:7
%     [sig2{i} state2{i} parm] = load_data();
% end
load('tmpAWBdata');
sig=sig2{1};
state=state2{1};
sig = sig'; % <-- to match bci2000 convention
% load('ChSetKruisienski'); clear idxBio_6 idxP3_18 idxP3_6
%% BCI 2000 main control loop
% Set global bci parameters/states
global bci_Parameters bci_States;
bci_Parameters = parm;
pred_label = [];
gt_labels =[];
predLabel=[];
% save('predLabel','predLabel');
% save('pred_label','pred_label');
% save('gt_labels','gt_labels');
in_signal_dims = [128 66];
out_signal_dims = [128 66];
bci_Parameters.TransmitChList = bci_Parameters.TransmitChList.Value;
bci_Parameters.SampleBlockSize = bci_Parameters.SampleBlockSize.Value;
blockSize = str2double( bci_Parameters.SampleBlockSize );
numBlocks = length(sig)/blockSize;  % total number of blocks in the run
onlineChannels = str2double(bci_Parameters.TransmitChList); % <- this is
% source of the problem!
% onlineChannels = [idxBio_18' 65 66]';

% constructor
bci_Construct(); tic;
% run bci sim over all files
for kk = 1:length(sig2)   
    idx = 1;    % current index in the signal
    % BCI Initialize (Run Once)
    bci_Initialize(in_signal_dims,out_signal_dims);
    % --- Main Loop ---
    for i =1:numBlocks
        % signal acquisition
        state = state2{kk}; 
        sig = sig2{kk};
        sig = sig';
        in_signal = sig(onlineChannels,idx:idx+blockSize-1);
        
        % state acquisition
        bci_States.StimulusCode = state.StimulusCode(idx);
        
        % run matlab filter over signal block
        out_signal = bci_Process(in_signal);
        
        % update index
        idx = idx + blockSize;
        
        % add small delay for realism
%         pause(0.1);
    end
    % bci Stop Run
    bci_StopRun();
end
toc;