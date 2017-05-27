clear all
clc
% ������ͨ�����ݷֱ���ȡ3��ARϵ����Ȼ����������һ���͵�������
featureData1 = [];
featureData2 = [];
for i = 1:15
		s1 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data3.txt'];
        s2 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data4.txt'];
        s3 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data7.txt'];
		data1 = importdata(s1,'\n');
        data2 = importdata(s2,'\n');
        data3 = importdata(s3,'\n');
 		AR1 = arburg(data1',3);
        AR2 = arburg(data2',3);
        AR3 = arburg(data3',3);
        AR = [AR1(2:4),AR2(2:4),AR3(2:4)];
 		featureData1 = [AR;featureData1];
%        featureData1 = [data';featureData1];
end

for i = 1:15
		s1 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data3.txt'];
        s2 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data4.txt'];
        s3 = ['C:\Users\Think\Desktop\EMG\2017-05-22\����\','��',num2str(i),'��\data7.txt'];
		data1 = importdata(s1,'\n');
        data2 = importdata(s2,'\n');
        data3 = importdata(s3,'\n');
 		AR1 = arburg(data1',3);
        AR2 = arburg(data2',3);
        AR3 = arburg(data3',3);
        AR = [AR1(2:4),AR2(2:4),AR3(2:4)];
 		featureData2 = [AR;featureData2];
%        featureData2 = [data';featureData2];
end


% plot3(featureData1(:,1),featureData1(:,2),featureData1(:,3),'r*',featureData2(:,1),featureData2(:,2),featureData2(:,3),'b*');

trainData = [featureData1(1:10,:);featureData2(1:10,:)];
trainLabel = [ones(10,1);zeros(10,1)];
testData = [featureData1(11:15,:);featureData2(11:15,:)];

% ѵ��1��svm������
% SVM = svmtrain(trainData,trainLabel);
load SVM 

for k=1:10
			result(k) = svmclassify(SVM,testData(k,:));
end

s = serial('COM3');
fopen(s);
fprintf(s,'%s\r\n',int2str(result));
pause(3);
fscanf(s)
pause(1);
fscanf(s)
fclose(s);