function scanInfoS = initializeScanInfo
%"initializeScanInfo"
%   Return a skeleton scanInfo struct of dimension 1x0.  Only the fields
%   exist.
%
%JRA 06/28/06
%AI  12/28/16 Added scale slope, intercept
%Usage:
%   scanInfoS = initializeScanInfo
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if nargout > 1
   error('Invalid number of outputs requested from initializeCERR.  Check for the new single output prototype!');
end

scanInfoS =  struct(...
'imageNumber'              ,   '', ...
'imageType'                ,   '', ...
'caseNumber'               ,   '', ...
'patientName'              ,   '', ...
'patientID'                ,   '', ...
'patientBirthDate'         ,   '', ...
'scanType'                 ,   '', ...
'CTOffset'                 ,   '', ...
'rescaleSlope'             ,   '', ...
'rescaleIntercept'         ,   '', ...
'scaleSlope'               ,   '', ...  
'scaleIntercept'           ,   '', ...  
'grid1Units'               ,   '', ...
'grid2Units'               ,   '', ...
'numberRepresentation'     ,   '', ...
'bytesPerPixel'            ,   '', ...
'numberOfDimensions'       ,   '', ...
'sizeOfDimension1'         ,   '', ...
'sizeOfDimension2'         ,   '', ...
'zValue'                   ,   '', ...
'xOffset'                  ,   '', ...
'yOffset'                  ,   '', ...
'CTAir'                    ,   '', ...
'CTWater'                  ,   '', ...
'sliceThickness'           ,   '', ...
'siteOfInterest'           ,   '', ...
'unitNumber'               ,   '', ...
'scanDescription'          ,   '', ...
'scannerType'              ,   '', ...
'manufacturer'             ,   '', ...
'scanFileName'             ,   '', ...
'headInOut'                ,   '', ...
'positionInScan'           ,   '', ...
'patientAttitude'          ,   '', ...
'bValue'                   ,   '', ...
'acquisitionDate'          ,   '', ...
'acquisitionTime'          ,   '', ...
'patientWeight'            ,   '', ...
'patientSize'              ,   '', ...
'patientBmi'               ,   '', ...
'patientSex'               ,   '', ...
'radiopharmaInfoS'         ,   '', ...
'injectionTime'            ,   '', ...
'injectedDose'             ,   '', ...
'halfLife'                 ,   '', ...
'imageUnits'               ,   '', ...
'suvType'                  ,   '', ...
'petCountSource'           ,   '', ...
'petSeriesType'            ,   '', ...
'petActivityConcentrationScaleFactor', '', ...
'petNumSlices'             ,   '', ...
'petIsDecayCorrected'      ,   '', ...
'petPrimarySourceOfCounts' ,   '', ...
'petDecayCorrectionDateTime',  '', ...
'decayCorrection'          ,   '', ...
'correctedImage'           ,   '', ...
'seriesDate'               ,   '', ...
'seriesTime'               ,   '', ...
'studyDate'                ,   '', ...
'studyTime'                ,   '', ...
'tapeOfOrigin'             ,   '', ...
'studyNumberOfOrigin'      ,   '', ...
'scanID'                   ,   '', ...
'scanNumber'               ,   '', ...
'scanDate'                 ,   '', ...
'CTScale'                  ,   '', ...
'distrustAbove'            ,   '', ...
'imageSource'              ,   '', ...
'transferProtocol'         ,   '', ...
'LRflippedToMatchPACS'     ,   '', ...
'APflippedToMatchPACS'     ,   '', ...
'SIflippedToMatchPACS'     ,   '', ...
'studyInstanceUID'         ,   '', ...
'seriesInstanceUID'        ,   '', ...
'sopInstanceUID'           ,   '', ...
'sopClassUID'              ,   '', ...
'frameOfReferenceUID'      ,   '', ...
'patientPosition'          ,   '', ...
'imageOrientationPatient'  ,   '', ...
'imagePositionPatient'     ,   '', ...
'windowCenter'             ,   '', ...
'windowWidth'              ,   '', ...
'temporalPositionIndex'    ,   '', ...
'frameAcquisitionDuration' ,   '', ...
'frameReferenceDateTime'   ,   '', ...
'DICOMHeaders'             ,   '');

scanInfoS(1) = [];