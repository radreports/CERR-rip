function [planC,origScanNum,success] = processAndImportSeg(planC,scanNumV,...
                                       fullSessionPath,userOptS)
% planC = processAndImportSeg(planC,scanNumV,fullSessionPath,userOptS);
%-------------------------------------------------------------------------
% INPUTS
% planC           : planC OR path to directory containing CERR files.
% scanNumV        : Scan nos required by model
% fullSessionPath : Full path to session dir
% userOptS        : Dictionary of post-processing parameters.
%-------------------------------------------------------------------------
% AI 9/21/21

%-For structname-to-label map
labelPath = fullfile(fullSessionPath,'outputLabelMap');

% Read structure masks
outFmt = userOptS.modelOutputFormat;
passedScanDim = userOptS.passedScanDim;
outC = stackDLMaskFiles(fullSessionPath,outFmt,passedScanDim);

% Import to CERR
success = 0;
if ~iscell(planC)
    cerrPath = planC;
    % Load from file
    planCfileS = dir(fullfile(cerrPath,'*.mat'));
    planCfilenameC = {planCfileS.name};

    for nFile = 1:length(planCfilenameC)
        tic
        planCfilename = fullfile(cerrPath, planCfilenameC{nFile});
        planC = loadPlanC(planCfilename,tempdir);

        %ptIdx = strcmp(fullSessionPath,planCfilename)
        ptIdx = nFile;
        segMask3M = outC{ptIdx};

        [origScanNum,planC] = importLabelMap(userOptS,scanNumV,...
            segMask3M,labelPath,planC);

        %Save planC
        optS = [];
        saveflag = 'passed';
        save_planC(planC,optS,saveflag,planCfilename);
        toc
    end
else
    segMask3M = outC{1};
    tic
    [origScanNum,planC] = importLabelMap(userOptS,scanNumV,...
        segMask3M,labelPath,planC);
    toc
end

success = 1;


%% ----- Supporting functions ----
    function [origScanNum,planC] = importLabelMap(userOptS,scanNumV,...
            segMask3M,labelPath,planC)

        indexS = planC{end};
        identifierS = userOptS.structAssocScan.identifier;
        if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
            origScanNum = getScanNumFromIdentifiers(identifierS,planC);
        else
            origScanNum = 1; %Assoc with first scan by default
        end
        outScanNum = scanNumV(origScanNum);
        userOptS.scan(outScanNum) = userOptS(origScanNum).scan;
        userOptS.scan(outScanNum).origScan = origScanNum;
        planC  = joinH5planC(outScanNum,segMask3M,labelPath,userOptS,planC);

        % Post-process segmentation
        if sum(segMask3M(:))>0
            fprintf('\nPost-processing results...\n');
            tic
            planC = postProcStruct(planC,userOptS);
            toc
        end

        % Delete intermediate (resampled) scans if any
        scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
        resampScanName = ['Resamp_scan',num2str(origScanNum)];
        matchIdxV = ismember(scanListC,resampScanName);
        if any(matchIdxV)
            deleteScanNum = find(matchIdxV);
            planC = deleteScan(planC,deleteScanNum);
        end

    end
end