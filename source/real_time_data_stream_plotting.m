% RealTime Data Streaming with Delsys SDK
% Date:2017/5/22 19:19:09
% Modefy:�ı��˼�������ֵ�ķ���������������n�������㣬��ȡƽ��
%  
%       ����       ����
%      �����ߩ�����������������
%      ��          ��
%      �� �ש�  ����   ��
%      ��    ��     ��
%      ������      ������
%        ��      ����������
%        ��  ���ޱ��өǩ�
%        ��������BUG ����
%        ������������������������
%         ���ϩ�    ���ϩ�
%         ���ߩ�    ���ߩ�  
%      
function real_time_data_stream_plotting


% CHANGE THIS TO THE IP OF THE COMPUTER RUNNING THE TRIGNO CONTROL UTILITY
HOST_IP = '10.66.126.203';
%%
% This example program communicates with the Delsys SDK to stream 16
% channels of EMG data and 48 channels of ACC data.



% Create the required objects

% Define number of sensors
NUM_SENSORS = 16;

% handles to all plots
global plotHandlesEMG;
plotHandlesEMG = zeros(NUM_SENSORS,1);
global rateAdjustedEmgBytesToRead;

%TCPIP Connection to stream EMG Data
interfaceObjectEMG = tcpip(HOST_IP,50041);
interfaceObjectEMG.InputBufferSize = 6400;

%TCPIP Connection to communicate with SDK, send/receive commands
commObject = tcpip(HOST_IP,50040);

%Timer object for drawing plots.
t = timer('Period', .1, 'ExecutionMode', 'fixedSpacing', 'TimerFcn', {@updatePlots, plotHandlesEMG});
global data_arrayEMG
data_arrayEMG = [];


%% Set up the plots


axesHandlesEMG = zeros(NUM_SENSORS,1);

%initiate the EMG figure
figureHandleEMG = figure('Name', 'EMG Data','Numbertitle', 'off',  'CloseRequestFcn', {@localCloseFigure, interfaceObjectEMG,  commObject, t});
set(figureHandleEMG, 'position', [50 200 750 750])

for i = 1:4 % ֻ��ʾ1~3ͨ�������ݣ����ĸ���ͼ������ʾ����
    axesHandlesEMG(i) = subplot(4,1,i);

    plotHandlesEMG(i) = plot(axesHandlesEMG(i),0,'-y','LineWidth',1);

    set(axesHandlesEMG(i),'YGrid','on');
    %set(axesHandlesEMG(i),'YColor',[0.9725 0.9725 0.9725]);
    set(axesHandlesEMG(i),'XGrid','on');
    %set(axesHandlesEMG(i),'XColor',[0.9725 0.9725 0.9725]);
    set(axesHandlesEMG(i),'Color',[.15 .15 .15]);
    set(axesHandlesEMG(i),'YLim', [-.005 .005]);
    set(axesHandlesEMG(i),'YLimMode', 'manual');
    set(axesHandlesEMG(i),'XLim', [0 2000]);
    set(axesHandlesEMG(i),'XLimMode', 'manual');
    
%     if(mod(i, 4) ~= 0)
%         ylabel(axesHandlesEMG(i),'V');
%     else
%         set(axesHandlesEMG(i), 'YTickLabel', '')
%     end
%     
%     if(i == 3)
%         xlabel(axesHandlesEMG(i),'Samples');
%     else
%         set(axesHandlesEMG(i), 'XTickLabel', '')
%     end
%     
    title(sprintf('EMG %i', i)) 
end

set(axesHandlesEMG(4),'XLim', [0 62]); % 2000/32=62.5;����ѹ�������ᣬ�൱��ѹ�����ݡ�
set(axesHandlesEMG(4),'YLim', [-.005 .005]);


% Open the COM interface, determine RATE

fopen(commObject);

pause(1);
fread(commObject,commObject.BytesAvailable);
fprintf(commObject, sprintf(['RATE 2000\r\n\r'])); % ������Ϊ2000hz
pause(1);
fread(commObject,commObject.BytesAvailable);
fprintf(commObject, sprintf(['RATE?\r\n\r']));
pause(1);
data = fread(commObject,commObject.BytesAvailable);

emgRate = strtrim(char(data'));
if(strcmp(emgRate, '1925.926'))
    rateAdjustedEmgBytesToRead=1664;
else 
    rateAdjustedEmgBytesToRead=1728;
end


%  Setup interface object to read chunks of data
% Define a callback function to be executed when desired number of bytes
% are availsable in the input buffer
 bytesToReadEMG = rateAdjustedEmgBytesToRead;
 interfaceObjectEMG.BytesAvailableFcn = {@localReadAndPlotMultiplexedEMG,plotHandlesEMG,bytesToReadEMG};
 interfaceObjectEMG.BytesAvailableFcnMode = 'byte';
 interfaceObjectEMG.BytesAvailableFcnCount = bytesToReadEMG;
 
 
drawnow
start(t);

% pause(1);
%% 
% Open the interface object
try
    fopen(interfaceObjectEMG);
catch
    localCloseFigure(1,interfaceObjectEMG, commObject, t);
    delete(figureHandleEMG);
    error('CONNECTION ERROR: Please start the Delsys Trigno Control Application and try again');
end



%%
% Send the commands to start data streaming
fprintf(commObject, sprintf(['START\r\n\r']));


%%
% Display the plot

% snapnow;


%  Implement the bytes available callback
% The localReadandPlotMultiplexed functions check the input buffers for the
% amount of available data, mod this amount to be a suitable multiple.

% Because of differences in sampling frequency between EMG and ACC data, the
% ratio of EMG samples to ACC samples is 13.5:1

% We use a ratio of 27:2 in order to keep a whole number of samples.  
% The EMG buffer is read in numbers of bytes that are divisible by 1728 by the
% formula (27 samples)*(4 bytes/sample)*(16 channels)
% The ACC buffer is read in numbers of bytes that are divisible by 384 by
% the formula (2 samples)*(4 bytes/sample)*(48 channels)
% Reading data in these amounts ensures that full packets are read.  The 
% size limits on the dataArray buffers is to ensure that there is always one second of
% data for all 16 sensors (EMG and ACC) in the dataArray buffers
function localReadAndPlotMultiplexedEMG(interfaceObjectEMG, ~,~,~, ~)
global rateAdjustedEmgBytesToRead;
bytesReady = interfaceObjectEMG.BytesAvailable;
bytesReady = bytesReady - mod(bytesReady, rateAdjustedEmgBytesToRead);% 1664

if (bytesReady == 0)
    return
end
global data_arrayEMG
data = cast(fread(interfaceObjectEMG,bytesReady), 'uint8');
data = typecast(data, 'single');




if(size(data_arrayEMG, 1) < rateAdjustedEmgBytesToRead*19)
    data_arrayEMG = [data_arrayEMG; data];
else
    data_arrayEMG = [data_arrayEMG(size(data,1) + 1:size(data_arrayEMG, 1));data];
end

    


% Update the plots
% This timer callback function is called on every tick of the timer t.  It
% demuxes the dataArray buffers and assigns that channel to its respective
% plot.
function updatePlots(obj, Event,  tmp)
global data_arrayEMG
global plotHandlesEMG

% �ֱ�ȡ��ͨ��3��4��7�����ݣ�����������ͨ����������
data_ch3 = data_arrayEMG(3:16:end);   
set(plotHandlesEMG(1), 'ydata', data_ch3)
data_ch4 = data_arrayEMG(4:16:end);  
set(plotHandlesEMG(2), 'ydata', data_ch4)
data_ch7 = data_arrayEMG(7:16:end);  
set(plotHandlesEMG(3), 'ydata', data_ch7)

len = size(data_ch3,1);
neng1 = calcuEnergy(len,0.0005,64,32,data_ch3);
neng2 = calcuEnergy(len,0.0005,64,32,data_ch4);
neng3 = calcuEnergy(len,0.0005,64,32,data_ch7);
neng = neng1 + neng2 + neng3; % nengΪ����ͨ����ӵ�����
disp(neng);
set(plotHandlesEMG(4),'Ydata', neng);

% Ѱ���ж���ʱ��ε���ʼ��ͽ�����
threadHoldValue = 0.0001 ; % ��ֵͨ��ʵ�����ݹ۲���ȡ
startPoint = 0 ; % ������ʼ���������ڵ���
endPoint = 0 ;   % �����������������ڵ���
nn = len ;
N = 64 ;
n = 32 ;
startPoint = startPointDetect(neng,nn,N,n,threadHoldValue); % �����ʼ��
if startPoint ~= 0 % ֻ�м�⵽��ʼ��ſ�ʼ��һ��������ļ��
   c_startPoint=n*(startPoint-1)+1;  % ������ʼ�Ĳ�������
   epp=startPoint+10;     % ��֤�����յ�������xxx�룬�ɼ�����������
   endPoint=endPointDetect(neng,nn,N,n,epp,threadHoldValue);
   if endPoint == 0
      disp('����Ч����!');	
   else
      % �ȼ�⵽��ʼ���ּ�⵽������Ž�����һ����ȡ���ݣ�������ʲô���������ȴ���һ��
      c_endPoint=n*(endPoint-1)+1;   % ���������Ĳ�������
      disp(c_startPoint);
      disp(c_endPoint);
      % ����ʵ��ѵ������
      fid1 = fopen('data3.txt','w');
      fid2 = fopen('data4.txt','w');
      fid3 = fopen('data7.txt','w');
      fprintf(fid1,'%f\r\n',data_ch3(c_startPoint:c_endPoint));
      fprintf(fid2,'%f\r\n',data_ch4(c_startPoint:c_endPoint));
      fprintf(fid3,'%f\r\n',data_ch7(c_startPoint:c_endPoint));
      fclose(fid1);
      fclose(fid2);
      fclose(fid3);
      % ��һ��arrayEMG�����ݱ����������Լ����μ���Ч��
      fid1 = fopen('data3_o.txt','w');
      fid2 = fopen('data4_o.txt','w');
      fid3 = fopen('data7_o.txt','w');
      fprintf(fid1,'%f\r\n',data_ch3);
      fprintf(fid2,'%f\r\n',data_ch4);
      fprintf(fid3,'%f\r\n',data_ch7);
      fclose(fid1);
      fclose(fid2);
      fclose(fid3);
      disp('OK');
      % set(plotHandlesEMG(4),'xdata',[startPoint,endPoint],'ydata',[0.0003,0.0003],'Color','red'); % ������Ч���ݷ�Χ
   end
else 
 	 disp('����Ч����!');
end

% drawnow
 
% ����һ�����ݵ�����ֵ    
function [sum_zu]=calcuEnergy(nn,tt,N,n,y)
sum_zu=[];
for j=1:nn/n
    if (1+(j-1)*n+N)>=nn
        break;
    end
    s1=0;
    for i=(1+(j-1)*n):(1+(j-1)*n+N)        %��������������
      s0(i)=abs(y(i));          %s0ΪС���������
      s1=s1+s0(i);              %s1Ϊ���ڵ����
    end
    sum_zu(j)=s1/64;
end

% �������
function stp=startPointDetect(neng,nn,N,n,A)
stp = 0 ;
for i=1:(nn-5*N)/n
    if neng(i)>A && neng(i+1)>A && neng(i+2)>A 
        stp=i;   %spΪͨ���ﵽ��ʼ��Ҫ��Ĵ��ں�
    end
    if stp ~= 0
        break
    end
end

% �����յ�
function enp=endPointDetect(neng,nn,N,n,epp,A)
enp=0;
for i=epp:(nn-5*N)/n
    if neng(i)<A && neng(i+1)<A && neng(i+2)<A && neng(i+3)<A && neng(i+4)<A && neng(i+5)<A
        enp(1)=i;   %pppΪ��ͨ���ﵽ��ʼ��Ҫ��Ĵ��ںţ�Ҫȡ��СֵΪ��ʼ�ָ��
    end
    if enp ~= 0
        break
    end
end

 
%  Implement the close figure callback
% This function is called whenever either figure is closed in order to close
% off all open connections.  It will close the EMG interface, ACC interface,
% commands interface, and timer object
function localCloseFigure(figureHandle,~,interfaceObject1,  commObject, t)
% Clean up the network objects
if isvalid(interfaceObject1)
    fclose(interfaceObject1);
    delete(interfaceObject1);
    clear interfaceObject1;
end

if isvalid(t)
   stop(t);
   delete(t);
end

if isvalid(commObject)
    fclose(commObject);
    delete(commObject);
    clear commObject;
end

%% 
% Close the figure window
delete(figureHandle);
