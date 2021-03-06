function bci_Initialize( in_signal_dims, out_signal_dims )
% linux path
addpath([pwd '/tools']);
addpath([pwd '/models']);

% windows path
% addpath([pwd '\tools']);
% addpath([pwd '\models']);

global modelRsvp smlThreshold bci_Parameters;
global previousSignal currentSignal udpSocket;
global ensembleScore ensembleLabel currentImage previousImage;

nchans = length(str2double( bci_Parameters.TransmitChList ));
if(nchans>18)
    nchans = nchans-2;
end
blockSize = str2double( bci_Parameters.SampleBlockSize );
% initialize global variables
ensembleScore=zeros(length(modelRsvp),1);
ensembleLabel=ensembleScore;
smlThreshold = 32;
previousSignal = zeros(nchans,blockSize);
currentSignal = zeros(nchans,blockSize);
previousImage=0;
currentImage=0;
% load models
% x=load('18ChModels');
% modelRsvp = x.modelRsvp;

x=load('18ChModels_Boosted');
tmp = x.BoostedRsvpModels{1,2};
for i=1:length(tmp)
    modelRsvptmp(i)=tmp{i};
end
modelRsvp=modelRsvptmp;

% Initialize UDP socket on local computer on port 1235
 udpSocket = udp('127.0.0.1',1235);
 fopen(udpSocket);
