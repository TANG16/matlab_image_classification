%% ���ݼ�
outputFolder='../../datasets/caltech101';
rootFolder = fullfile(outputFolder, '101_ObjectCategories');

% �������ݼ�
categoriesFolders=dir(rootFolder);
categoriesFolders(1:3)=[];
categories= {categoriesFolders(:).name}';
% categories=categories(randperm(length(categories),20));
% categories=categories(1:10);

imds = imageDatastore(fullfile(rootFolder, categories), 'LabelSource', 'foldernames');

%% 
% ��ʾ��������
tbl = countEachLabel(imds);
tbl(1:5,:)

%%
% Ϊ��ʹ������������ƽ�⣬ѡȡ�������ٵ�Ϊ��׼��ȡ����
minSetCount = min(tbl{:,2}); 
imds = splitEachLabel(imds, minSetCount, 'randomize');
tbl = countEachLabel(imds)
tbl(1:5,:)

%% �ָ�����
% �����������Ϊѵ�����Ͳ��Լ�
[trainingSet, validationSet] = splitEachLabel(imds, 0.3, 'randomize');

%% ��ȡ bag of words �ʵ�
bag = bagOfFeatures(trainingSet);

%%
% ���ݴʵ�ѵ��������
categoryClassifier = trainImageCategoryClassifier(trainingSet, bag);

%% ���Է�����
% ����ѵ����
confMatrix = evaluate(categoryClassifier, trainingSet);
mean(diag(confMatrix))

% ���Բ��Լ�
confMatrix = evaluate(categoryClassifier, validationSet);
mean(diag(confMatrix))

%% ���������
save('classifier','categoryClassifier');
