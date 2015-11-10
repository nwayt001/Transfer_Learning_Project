function bci_StopRun

% Filter stop run demo
% 
% Perform parameter updates at the end of a run.

% BCI2000 filter interface for Matlab
% juergen.mellinger@uni-tuebingen.de, 2005
% $BEGIN_BCI2000_LICENSE$
% 
% This file is part of BCI2000, a platform for real-time bio-signal research.
% [ Copyright (C) 2000-2012: BCI2000 team and many external contributors ]
% 
% BCI2000 is free software: you can redistribute it and/or modify it under the
% terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.
% 
% BCI2000 is distributed in the hope that it will be useful, but
%                         WITHOUT ANY WARRANTY
% - without even the implied warranty of MERCHANTABILITY or FITNESS FOR
% A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License along with
% this program.  If not, see <http://www.gnu.org/licenses/>.
% 
% $END_BCI2000_LICENSE$

% Parameters and states are global variables.
global udpSocket pred_label gt_labels predLabel pred_score blockLength;
global bci_Parameters;

pd = pwd;
dir = [pd(1:end-16) bci_Parameters.DataDirectory.Value{1}(4:end) '\' bci_Parameters.SubjectName.Value{1} ...
    bci_Parameters.SubjectSession.Value{1} '\'];

% Calculate the total balanced accuracy so far
Pi = balancedAccuracy(predLabel,gt_labels);

% Calculate the total balanced accuracy of the previous run
PiRun = balancedAccuracy(predLabel(end-(blockLength-1):end),gt_labels(end-(blockLength-1):end));

display(['Accuracy Previous Block: ' num2str(PiRun)]);
display(['Total Accuracy: ' num2str(Pi)]);

% Send the accuracy to the C# app for feedback
fb = ['A1'  'S' num2str(Pi)];
 fwrite(udpSocket,fb); 
fb = ['K1'  'S' num2str(PiRun)];
 fwrite(udpSocket,fb);
% close out the udp socket at the end of the run
 fclose(udpSocket);

% save the predicted labels and gt from the previous run for each subject
save([dir 'pred_label'],'pred_label');
save([dir 'predLabel'],'predLabel');
save([dir 'gt_labels'],'gt_labels');
save([dir 'pred_score'],'pred_score');
save([dir 'OnlineAccuracy'],'Pi');