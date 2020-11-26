function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp, rebuildRS)
% function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp,rebuildRS)
%
% This function imports DICOM files from dicomPath and adds header info
% with XNAT addressing metadata

if ~exist('rebuildRS','var')
    rebuildRS = 0;
end

if strcmpi(rebuildRS,'Y')
    rebuildRS = 1;
end
disp(['importing DICOM from ' dicomPath]);
importDICOM(dicomPath,cerrPath);

cerrFile = dir(fullfile(cerrPath, '*.mat'));

planC = loadPlanC(cerrFile);

planC = annotatePlanCForXNAT(planC, xhost,xexp,xproj,xsubj);

if rebuildRS
    planC = reviveRS(planC,cerrPath);
end

save_planC(planC,[],'passed',cerrFile);