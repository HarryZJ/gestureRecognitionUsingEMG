clear all
clc
for i = 1:15
		s1 = ['C:\Users\Think\Desktop\EMG\2017-05-22\上屈\','第',num2str(i),'组\data3.txt'];
	  s2 = ['C:\Users\Think\Desktop\EMG\2017-05-22\上屈\','第',num2str(i),'组\data4.txt'];
	  s3 = ['C:\Users\Think\Desktop\EMG\2017-05-22\上屈\','第',num2str(i),'组\data7.txt'];
    data1 = importdata(s1,'\n');
    data2 = importdata(s2,'\n');
    data3 = importdata(s3,'\n');
	  dataArray = [data1';data2';data3'];
	  s = ['C:\Users\Think\Desktop\EMG\2017-05-22\上屈\','第',num2str(i),'组\dataArray',num2str(i),'.txt'];
	  fid = fopen(s,'w');
	  fprintf(fid,'%f\r\n',dataArray);
	  fclose(fid);
end
