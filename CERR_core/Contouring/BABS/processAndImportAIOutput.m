function [planC,allLabelNamesC,dcmExportOptS] = ...
    processAndImportAIOutput(planC,userOptS,origScanNumV,scanNumV,...
    outputScanNum,algorithm,hashID,sessionPath,cmdFlag,inputIdxS)
%[planC,,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
%processAndImportAIOutput(planC,userOptS,origScanNumV,scanNumV,...
% outputScanNum,algorithm,hashID,sessionPath,cmdFlag,inputIdxS)
%--------------------------------------------------------------------------
% AI 08/29/22

outputS = userOptS.output;
allLabelNamesC = {};
dcmExportOptS = struct([]);

%Loop over model outputs

outputC = fieldnames(outputS);
for nOut = 1:length(outputC)

    outType = outputC{nOut};

    switch(lower(outType))

        case 'labelmap'
            %Segmentations

            % Import segmentations
            if ishandle(hWait)
                waitbar(0.9,hWait,'Importing segmentation results to CERR');
            end
            [planC,allLabelNamesC,dcmExportOptS] = ...
                processAndImportSeg(planC,origScanNumV,scanNumV,...
                outputScanNum,sessionPath,userOptS);

        case 'dvf'
            %Deformation vector field

            outFmt = outputS.DVF.outputFormat;
            DVFpath = fullfile(sessionPath,'outputH5','DVF');
            DVFfile = dir([DVFpath,filesep,'*.h5']);
            outFile = fullfile(DVFpath,DVFfile.name);
            switch(lower(outFmt))
                case 'h5'
                    DVF4M = h5read(outFile,'/dvf');
                otherwise
                    error('Invalid model output format %s.',outFmt)
            end


            % Convert to CERR coordinate sytem

            if ~iscell(planC)
                cerrDir = planC;
                cerrDirS = dir(cerrDir);
                cerrFile = cerrDirS(3).name;
                planC = loadPlanC(fullfile(cerrDir,cerrFile),tempdir);
            else
                cerrFile = '';
            end
            indexS = planC{end};

            % Get associated scan num
            idS = userOptS.outputAssocScan.identifier;
            assocScan = getScanNumFromIdentifiers(idS,planC);

            tempOptS = userOptS;
            outTypesC = fieldnames(userOptS.output);
            matchIdx = strcmpi(outTypesC,'DVF');
            outTypesC = outTypesC(~matchIdx);
            tempOptS.output = rmfield(tempOptS.output,outTypesC);
            niiOutDir = tempOptS.output.DVF.outputDir;
            DVFfilename = strrep(DVFfile.name,'.h5','');
            dimsC = {'dx','dy','dz'};
            niiFileNameC = cell(1,length(dimsC));
            for nDim = 1:size(DVF4M,1)
                DVF3M = squeeze(DVF4M(nDim,:,:,:));
                DVF3M = permute(DVF3M,[2,3,1]);
                [DVF3M,planC] = joinH5planC(assocScan,DVF3M,[DVFfilename,'_'...
                    dimsC{nDim}],tempOptS,planC);
                niiFileNameC{nDim} = fullfile(niiOutDir,[DVFfilename,'_'...
                    dimsC{nDim},'.nii.gz']);
                fprintf('\n Writing DVF to file %s\n',niiFileNameC{nDim});
                DVF3M_nii = make_nii(DVF3M);
                save_nii(DVF3M_nii, niiFileNameC{nDim}, 0);
            end

            %Calc. deformation magnitude
            DVFmag3M = zeros(size(DVF3M));
            assocScanUID = planC{indexS.scan}(assocScan).scanUID;    
            for nDim = 1:size(DVF4M,1)
                doseNum = length(planC{indexS.dose})-nDim+1;
                doseArray3M = double(getDoseArray(doseNum,planC));
                DVFmag3M = DVFmag3M + doseArray3M.^2;
            end
            DVFmag3M = sqrt(DVFmag3M);
            description = 'Deformation magnitude';
            planC = dose2CERR(DVFmag3M,[],description,'',description,...
                'CT',[],'no',assocScanUID, planC);

            % Store to deformS
            indexS = planC{end};
            idS = userOptS.register.baseScan.identifier;
            baseScanNum = getScanNumFromIdentifiers(idS,planC,1);
            idS = userOptS.register.movingScan.identifier;
            movScanNum = getScanNumFromIdentifiers(idS,planC,1);

            planC{indexS.deform}(end+1).baseScanUID = ...
                planC{indexS.scan}(baseScanNum).scanUID;
            planC{indexS.deform}(end+1).movScanUID = ...
                planC{indexS.scan}(movScanNum).scanUID;

            planC{indexS.deform}(end+1).algorithm = algorithm;
            planC{indexS.deform}(end+1).registrationTool = 'CNN';
            planC{indexS.deform}(end+1).algorithmParamsS.singContainerHash = ...
                hashID;
            planC{indexS.deform}(end+1).DVFfileName = niiFileNameC;

            if ~isempty(cerrFile)
                save_planC(planC,[],'PASSED',cerrFile);
                planC = cerrFile;
            end

        case 'derivedimage'
            %Read output image
            outFmt = outputS.derivedImage.outputFormat;
            outputImgType = outputS.derivedImage.imageType;
            imgPath = fullfile(sessionPath,['output',outFmt],'derivedImage');
            imgFile = dir(imgPath);
            imgFile(1:2) = [];

            switch(lower(outFmt))

                case 'h5'

                    %Get unique dataset names
                    datasetsC = {};
                    for nFile = 1:length(imgFile)  %Note: Assumes 3D output
                        outFile =  fullfile(imgPath,imgFile(nFile).name);
                        I = h5info(outFile);
                        if isempty(datasetsC)
                            datasetsC{1} = I.Datasets.Name;
                        elseif ~ismember(I.Datasets,datasetsC)
                            datasetsC{end+1} = I.Datasets.Name;
                        end

                        %Read output
                        img3M = h5read(outFile,['/',I.Datasets.Name]);

                        %Import to CERR as texture map
                        indexS = planC{end};
                        initTextureS = initializeCERR('texture');
                        initTextureS(end+1).textureUID = createUID('texture');
                        planC{indexS.texture} = ...
                            dissimilarInsert(planC{indexS.texture},initTextureS);
                        currentTexture = length(planC{indexS.texture});
                        planC{indexS.texture}(currentTexture).textureUID = ...
                            createUID('TEXTURE');
                        
                        %Get associated scan index
                        assocScanNum = 1; %Assoc with first scan by default
                        if ~isempty(inputIdxS)
                            assocScanNum = inputIdxS.scan.scanNum;
                        else
                            identifierS = userOptS.outputAssocScan.identifier;
                            idS = rmfield(identifierS,{'warped','filtered'});
                            idC = fieldnames(idS);
                            if ~isempty(idC)
                                assocScanNum = getScanNumFromIdentifiers(identifierS,planC);
                            end
                        end
                        assocScanUID = planC{indexS.scan}(assocScanNum).scanUID;
                        planC{indexS.texture}(currentTexture).assocScanUID = assocScanUID;
                        
                        %Get associated structure index
                        sizeV = size(getScanArray(assocScanNum,planC));
                        minc = 1;
                        maxr = sizeV(1);
                        uniqueSlicesV = 1:sizeV(3);
                        strIdx = [];
                        if ~isempty(inputIdxS)
                            strIdx = inputIdxS.structure.strNum;                            
                        elseif isfield(userOptS.input,'structure')
                            strC = {planC{indexS.structures}.structureName};
                            if isfield(userOptS.input.structure,'name')
                                strName =  userOptS.input.structure.name;
                            else
                                if isfield(userOptS.input.structure,'strNameToLabelMap')
                                    strName =  userOptS.input.structure.strNameToLabelMap.structureName;
                                end
                            end
                            strIdx = getMatchingIndex(strName,strC,'EXACT');
                        end
                        
                        if ~isempty(strIdx)
                            assocStrUID = planC{indexS.structures}(strIdx).strUID;
                            planC{indexS.texture}(currentTexture).assocStructUID = assocStrUID;
                            mask3M = getStrMask(strIdx,planC);
                            [~,maxr,minc,~,~,~] = compute_boundingbox(mask3M);
                            uniqueSlicesV = find(sum(sum(mask3M))>0);
                        end

                        
                        % Assign parameters based on category of texture
                        planC{indexS.texture}(currentTexture).parameters = ...
                            userOptS;
                        planC{indexS.texture}(currentTexture).description = ...
                            [algorithm,'_',I.Datasets];

                        % Create Texture Scans
                        [xValsV, yValsV, zValsV] = ...
                            getScanXYZVals(planC{indexS.scan}(assocScanNum));
                        dx = median(diff(xValsV));
                        dy = median(diff(yValsV));
                        zV = zValsV(uniqueSlicesV);
                        regParamsS.horizontalGridInterval = dx;
                        regParamsS.verticalGridInterval = dy;
                        regParamsS.coord1OFFirstPoint = xValsV(minc);
                        regParamsS.coord2OFFirstPoint   = yValsV(maxr);
                        regParamsS.zValues  = zV;
                        regParamsS.sliceThickness = ...
                            [planC{indexS.scan}(assocScanNum).scanInfo(uniqueSlicesV).sliceThickness];
                        assocTextureUID = planC{indexS.texture}(currentTexture).textureUID;

                        %Save to planC
                        planC = scan2CERR(img3M,outputImgType,'Passed',regParamsS,...
                            assocTextureUID,planC);

                    end

                otherwise %TBD extend to support other formats
                    error('Invalid model output format %s.',outFmt)
            end

        otherwise
            error('Invalid output type '' %s ''.',outType)


    end
    userOptS.output.(outType) =  outputS;

end

end