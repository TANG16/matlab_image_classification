%% ���ϵͳ����
deviceInfo = gpuDevice;

computeCapability = str2double(deviceInfo.ComputeCapability);
assert(computeCapability > 3.0, ...
    'This example requires a GPU device with compute capability 3.0 or higher.')

%% ���ݼ�
datasetsFolder = '../../datasets/caltech101'; % define output folder
url = 'http://www.vision.caltech.edu/Image_Datasets/Caltech101/101_ObjectCategories.tar.gz';
if ~exist(datasetsFolder, 'dir') % download only once
    disp('Downloading 126MB Caltech101 data set...');
    untar(url, datasetsFolder);
end
% �������ݼ�
rootFolder = fullfile(datasetsFolder, '101_ObjectCategories');
categoriesFolders=dir(rootFolder);
categoriesFolders(1:3)=[];
categories= {categoriesFolders(:).name}';
% categories=categories(randperm(length(categories),20));
% categories=categories(1:10);

imds = imageDatastore(fullfile(rootFolder, categories), 'LabelSource', 'foldernames');

%%
% ��ʾ��������
tbl = countEachLabel(imds)
%%
% Ϊ��ʹ������������ƽ�⣬ѡȡ�������ٵ�Ϊ��׼��ȡ����

minSetCount = min(tbl{:,2});

imds = splitEachLabel(imds, minSetCount, 'randomize');

countEachLabel(imds)
%% ����AlexNet CNN����
cnnURL = 'http://www.vlfeat.org/matconvnet/models/beta16/imagenet-caffe-alex.mat';
cnnMatFile = fullfile('../../alexnet', 'imagenet-caffe-alex.mat');
if ~exist(cnnMatFile, 'file') % download only once     
    disp('Downloading pre-trained CNN model...');     
    websave(cnnMatFile, cnnURL);
end
convnet = helperImportMatConvNet(cnnMatFile)

%% չʾCNN�ṹ
convnet.Layers
% չʾ��һ��ṹ
convnet.Layers(1)
% չʾ���һ��ṹ
convnet.Layers(end)
% ԭʼCNN�������������
numel(convnet.Layers(end).ClassNames)

%% ͼ��Ԥ����
% AlexNet CNN��227 227 3��RGBͼ����Ϊ����
% ����ѽ��������쵽227*227��ת��ΪRGBͼ��ĺ���
% ��ΪimageDatastore�Ķ�ȡʱ���õĺ���
imds.ReadFcn = @(filename)readAndPreprocessImage(filename);

%% �ָ�����
% �����������Ϊѵ�����Ͳ��Լ�
[trainingSet, testSet] = splitEachLabel(imds, 0.3, 'randomize');

%% ѡȡCNN��fc7�������Ϊ��������
featureLayer = 'fc7';
trainingFeatures = activations(convnet, trainingSet, featureLayer, ...
    'MiniBatchSize', 32, 'OutputAs', 'columns');

%% ѵ�������SVM
trainingLabels = trainingSet.Labels;

% ѡ������svm
classifier = fitcecoc(trainingFeatures, trainingLabels, ...
    'Learners', 'svm', 'Coding', 'onevsall', 'ObservationsIn', 'columns');

%% ���Է�����
% ����ѵ����
predictedLabels = predict(classifier, trainingFeatures');

% ��ȡѵ������������
confMat = confusionmat(trainingLabels, predictedLabels);

% ת��Ϊ�ٷֱ�
confMat = bsxfun(@rdivide,confMat,sum(confMat,2))

% ��ʾ����
mean(diag(confMat))


% ��ȡ���Լ���������
testFeatures = activations(convnet, testSet, featureLayer, 'MiniBatchSize',32);
predictedLabels = predict(classifier, testFeatures);

testLabels = testSet.Labels;

confMat = confusionmat(testLabels, predictedLabels);

confMat = bsxfun(@rdivide,confMat,sum(confMat,2))

mean(diag(confMat))

%% ����SVM������
save('classifier','classifier');


%% Ԥ������
function Iout = readAndPreprocessImage(filename)

I = imread(filename);

% �ѻҶ�ͼ��ת��ΪRGBͼ��
if ismatrix(I)
    I = cat(3,I,I,I);
end

% ���쵽277*277
Iout = imresize(I, [227 227]);
end
