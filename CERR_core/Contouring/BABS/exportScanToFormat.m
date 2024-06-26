function exportScanToFormat(exportFormat,scanNum,outDir,filePrefix,planC)
% function exportScanToFormat(exportFormat,scanNum,outDir,filePrefix,planC)
%
% Wrapper function to export scan to format such as NRRD, NIFTI.
%
% %Example:
% exportFormat = 'NRRD';
% scanNum = 1;
% outDir = '/path/to/output/dir';
% filePrefix = 'myFileName';
% exportScanTo(exportFormat,scanNum,outDir,filePrefix,planC)

% APA, 8/16/2021

indexS = planC{end};
scan3M = double(planC{indexS.scan}(1).scanArray) - ...
    double(planC{indexS.scan}(1).scanInfo(1).CTOffset);
[affineOutM,~,voxSizV] = getPlanCAffineMat(planC, scanNum, 1);
originV = affineOutM(1:3,4);
coordInfoS(1).affineM = affineOutM;
coordInfoS(1).originV = originV;
coordInfoS(1).voxSizV = voxSizV;
passedScanDim = '3D';
outDirC = {outDir};
scanC{1} = {scan3M};
testFlag = true;
writeDataForDL(scanC,{},coordInfoS,passedScanDim,exportFormat,outDirC,...
    filePrefix,testFlag)

