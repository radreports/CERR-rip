function planC  = joinH5planC(scanNum,segMask3M,labelPath,userOptS,planC)
% function planC  = joinH5planC(scanNum,segMask3M,labelPath,userOptS,planC)

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

isUniform = 0;
preserveAspectFlag = 0;
scanOptS = userOptS.input.scan(scanNum);

%Get output settings for label maps
labelOptS = userOptS.output.labelMap;

%% Resize/pad mask to original dimensions
%Get parameters for resizing & cropping
cropS = scanOptS.crop; %Added

% cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, ~, planC] = getCropLimits(planC,segMask3M,...
    scanNum,cropS);
scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
maskOut3M = zeros(sizV, 'uint32');
originImageSizV = [sizV(1:2), length(slcV)];

%Undo resizing & cropping
resizeS = scanOptS.resize;

for nMethod = length(resizeS):-1:1

    resizeMethod = resizeS(nMethod).method;

    if isfield(resizeS(nMethod),'preserveAspectRatio') && ...
            strcmp(resizeS(nMethod).preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    end

    if nMethod<length(resizeS)
        segMask3M = maskOut3M;
    end
    switch lower(resizeMethod)

        case 'pad2d'

            maskOut3M = zeros(sizV, 'uint32');
            limitsM = [minr, maxr, minc, maxc];
            resizeMethod = 'unpad2d';
            originImageSizV = [sizV(1:2), length(slcV)];
            [~, maskOut3M(:,:,slcV)] = ...
                resizeScanAndMask(segMask3M,segMask3M,originImageSizV,...
                resizeMethod,limitsM);

        case 'pad3d'
            resizeMethod = 'unpad3d';
            [~, tempMask3M] = ...
                resizeScanAndMask([],segMask3M,sizV,resizeMethod);
            maskOut3M(:,:,slcV) = tempMask3M;

        case 'padorcrop3d'
             resizeMethod = 'padorcrop3d';
            [~, tempMask3M] = ...
                resizeScanAndMask([],segMask3M,sizV,resizeMethod);
            maskOut3M(:,:,slcV) = tempMask3M;

        case 'padorcrop2d'
            resizeMethod = 'padorcrop2d';
            limitsM = [minr, maxr, minc, maxc];
            originImageSizV = [sizV(1:2), length(slcV)];
            [~, maskOut3M(:,:,slcV)] = ...
                resizeScanAndMask([],segMask3M,originImageSizV,...
                resizeMethod,limitsM);

        case 'padslices'
            resizeMethod = 'unpadslices';
            [~, maskOut3M] = ...
                resizeScanAndMask([],segMask3M,originImageSizV(3),resizeMethod);

        case { 'bilinear', 'sinc', 'bicubic'}
            maskOut3M = zeros(sizV, 'uint32');
            limitsM = [minr, maxr, minc, maxc];

            outSizeV = [maxr-minr+1,maxc-minc+1,originImageSizV(3)];
            [~,tempMask3M] = ...
                resizeScanAndMask([],segMask3M,outSizeV,resizeMethod,...
                limitsM,preserveAspectFlag);

            if size(limitsM,1)>1
                %2-D resize methods
                maskOut3M(:,:,slcV) = tempMask3M;
            else
                %3-D resize methods
                maskOut3M(minr:maxr, minc:maxc, slcV) = tempMask3M;
            end

        case 'none'
            maskOut3M(minr:maxr,minc:maxc,slcV) = segMask3M;
    end
end

%% Resample to original resolution
resampleS = scanOptS.resample;
if ~strcmpi(resampleS.method,'none')
    fprintf('\n Resampling masks...\n');
    % Get the new x,y,z grid
    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    %Get original grid
    origScanNum = scanOptS.origScan;
    [xVals0V, yVals0V, zVals0V] = getScanXYZVals(planC{indexS.scan}(origScanNum));
    if yVals0V(1) > yVals0V(2)
        yVals0V = fliplr(yVals0V);
    end
    %Resample mask ('nearest' interpolation)
    [~,maskOut3M] = resampleScanAndMask([],double(maskOut3M),xValsV,...
        yValsV,zValsV,xVals0V,yVals0V,zVals0V);

    scanNum = origScanNum;
end

%% Copy auto-segmentations to user-defined scan
%Get autosegmented structure names
[outStrListC,labelMapS] = getAutosegStructnames(labelPath,labelOptS);
if isfield(userOptS,'register') && ~isempty(fieldnames(userOptS.register))
    regS = userOptS.register;
    regMethod = regS.method;

    baseIdS = regS.baseScan.identifier;
    baseIdS.filtered = 0;
    baseScan = getScanNumFromIdentifiers(baseIdS,planC);

    movIdS = regS.movingScan.identifier;
    movIdS.filtered = 0;
    movScan = getScanNumFromIdentifiers(movIdS,planC);

    assocIdS = userOptS.outputAssocScan.identifier;
    assocScan = getScanNumFromIdentifiers(assocIdS,planC);
    strC = {planC{indexS.structures}.structureName};
    if baseScan==assocScan
        %Associate auto-segmentations with base scan
        scanNum = baseScan;
    elseif movScan==assocScan
        %Associate auto-segmentations with moving scan
        regMovScan = find(strcmp({planC{indexS.scan}.scanType},...
            ['Reg_scan',num2str(movScan)]));

        if ~strcmp(regMethod,'none')
            [planC,deformS] = registerScansForDLS(planC,[regMovScan,movScan],...
                regS.method,regS);
            tmpCmdDir = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
            maskOut3M(:) = 0;
            for nStr = 1:length(outStrListC)
                matchIdxV = getMatchingIndex(outStrListC{nStr},strC,'EXACT');
                assocScanV = getStructureAssociatedScan(matchIdxV,planC);
                cpyStr = matchIdxV(assocScanV==scanNum);
                planC = warp_structures(deformS,movScan,cpyStr,...
                    planC,planC,tmpCmdDir,0);
                strIdx = length(planC{indexS.structures});
                strMask3M = getStrMask(strIdx,planC);
                maskOut3M(strMask3M) = labelMapS.label;
            end
            scanNum = movScan;
        else
            error('Association with selected scan not supported');
        end
    else
        scanNum = assocScan;
    end
    %Delete derived scans ( filtered/registered)
    filtMovScanC = strfind({planC{indexS.scan}.scanType},'Filt_scan');
    filtMovScanV = find([filtMovScanC{:}]);
    regMovScanC = strfind({planC{indexS.scan}.scanType},'Reg_scan');
    regMovScanV = [regMovScanC{:}];
    deleteScanV = sort([filtMovScanV,regMovScanV],'descend');
    for scanIdx = 1:length(deleteScanV)
        planC = deleteScan(planC,deleteScanV(scanIdx));
    end
end


%% Convert label maps to CERR structs
roiGenerationDescription = '';
if isfield(labelOptS,'roiGenerationDescription')
    roiGenerationDescription = labelOptS.roiGenerationDescription;
end
for i = 1 : length(labelMapS)
    labelVal = labelMapS(i).value;
    maskForStr3M = maskOut3M == labelVal;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum,...
        outStrListC{i}, planC);
    planC{indexS.structures}(end).roiGenerationAlgorithm = 'AUTOMATIC';
    planC{indexS.structures}(end).roiGenerationDescription = roiGenerationDescription;
    planC{indexS.structures}(end).structureDescription = roiGenerationDescription;
end
end