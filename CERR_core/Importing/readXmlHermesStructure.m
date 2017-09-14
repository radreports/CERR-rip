% readXmlHermesStructure.m
%
% APA, 8/31/2017

fName = 'L:\Data\TCIA_Breast\Ivan\TCGA-AO-A03V\TCGAAOA03VTCGAAO_196070.xml';

global planC
indexS = planC{end};

% Read matrix coordinates
DOMnode = xmlread(fName);
xCoords = DOMnode.getElementsByTagName('x');
yCoords = DOMnode.getElementsByTagName('y');
zCoords = DOMnode.getElementsByTagName('z');
numPoints = xCoords.getLength();
xV = zeros(numPoints,1);
yV = zeros(numPoints,1);
zV = zeros(numPoints,1);
for i = 0:numPoints-1
   xCoord = xCoords.item(i); 
   yCoord = yCoords.item(i);
   zCoord = zCoords.item(i);
   xV(i+1) = str2double(xCoord.item(0).getData());
   yV(i+1) = str2double(yCoord.item(0).getData());
   zV(i+1) = str2double(zCoord.item(0).getData());
end

% parameters to convert from matrix to physical
scanNum = 1;
sizV = size(planC{indexS.scan}(scanNum).scanArray);
gridUnitsV = [planC{indexS.scan}(scanNum).scanInfo(1).grid1Units, ...
    planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
offsetV = [planC{indexS.scan}(scanNum).scanInfo(1).yOffset, ...
    planC{indexS.scan}(scanNum).scanInfo(1).xOffset];

patPos = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.PatientPosition;

switch upper(patPos)
    case 'HFS' %+x,-y,-z
        error('unknown position')
    case 'HFP' %-x,+y,-z
        error('unknown position')
    case 'FFS' %+x,-y,-z
        error('unknown position')
    case 'FFP' %-x,+y,-z
        yV = sizV(1)-yV;
        xV = sizV(2)-xV;
    otherwise
        error('unknown position')
end

% Convert to physical coordinates
[xAAPM, yAAPM] = mtoaapm(yV, xV, sizV(1:2), gridUnitsV, [0 0]);

% Create CERR structure
[~,~,zScanV] = getScanXYZVals(planC{indexS.scan}(1));
structS = newCERRStructure(scanNum,planC);

for slc = 1:length(structS.contour)
    
    indV = zV == slc-1;
    if any(indV)
        structS.contour(slc).segments.points = [xAAPM(indV) yAAPM(indV) zScanV(slc)*xV(indV).^0];
    end
    
end

structS.structureName = 'tumor';
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, structS);
planC = getRasterSegs(planC);

% refresh viewer
global stateS
if ~isempty(stateS)
    stateS.structsChanged = 1;
    CERRRefresh
end