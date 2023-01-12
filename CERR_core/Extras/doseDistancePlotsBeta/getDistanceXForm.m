function [dist3M, xV, yV, zV] = getDistanceXForm(structNum, minDistance, resolution, xV, yV, zV)%dist3M = getDistanceXForm, returns the 3-D distance transform,%giving the distance from each sampled point to the surface.  If the%resolution is the empty matrix, the CT resolution is used and the returned%distance transform applies to each CT element.%This routine is very similar to doseDistancePlot.m.%%Latest modifications:  JOD, 5 May 03, first version.%% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.% % This file is part of The Computational Environment for Radiotherapy Research (CERR).% % CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.% % CERR has been financially supported by the US National Institutes of Health under multiple grants.% % CERR is distributed under the terms of the Lesser GNU Public License. % %     This version of CERR is free software: you can redistribute it and/or modify%     it under the terms of the GNU General Public License as published by%     the Free Software Foundation, either version 3 of the License, or%     (at your option) any later version.% % CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.% See the GNU General Public License for more details.% % You should have received a copy of the GNU General Public License% along with CERR.  If not, see <http://www.gnu.org/licenses/>.global stateS planC  %Note planC may need to be updated with DSH points.indexS = planC{end};if isempty(resolution)  resolution = planC{indexS.scan}.scanInfo(1).grid1Units;end%First get the surface points mask and their positions:disp('Get surface points...')pointsM = planC{indexS.structures}(structNum).DSHPoints;if isempty(pointsM)  %-----Get any dose surface points--------%  planC =  getDSHPoints(planC, stateS.optS, structNum);  pointsM = planC{indexS.structures}(structNum).DSHPoints;endzSurfV = pointsM(:,3);ySurfV = pointsM(:,2);xSurfV = pointsM(:,1);%[mask3MU, xSurfV, ySurfV, zSurfV] = getStructSurface(structNum, planC);disp('Surface points established.')%If no specific coordinates passed in, calculate.if ~exist('xV','var') || ~exist('yV','var') || ~exist('zV','var')  	disp('Getting distance transform...')	%Next get the x, y, and z limits.		x_low = min(xSurfV) - minDistance;	x_high = max(xSurfV) + minDistance;		y_low = min(ySurfV) - minDistance;	y_high = max(ySurfV) + minDistance;		z_low = min(zSurfV) - minDistance;	z_high = max(zSurfV) + minDistance;		%Get corresponding nearest voxels:		sliceNum = 1; %doesn't matter...		[row1, col1] = xytom(x_low, y_low, sliceNum, planC);		row1 = round(row1);	col1 = round(col1);		[row2, col2] = xytom(x_low, y_high, sliceNum, planC);		row2 = round(row2);	col2 = round(col2);		[row3, col3] = xytom(x_high, y_low, sliceNum, planC);		row3 = round(row3);	col3 = round(col3);		[row4, col4] = xytom(x_high, y_high, sliceNum, planC);		row4 = round(row4);	col4 = round(col4);		s = planC{indexS.scan}.scanInfo(1).sizeOfDimension1;		rV = clip([row1, row2, row3, row4],1,s,'limits');	cV = clip([col1, col2, col3, col4],1,s,'limits');		%Get z values:	zValues    = [planC{indexS.scan}.scanInfo(:).zValue];		z1 = min(abs(zValues - z_low));	z2 = min(abs(zValues - z_high));		ind1 = find(abs(zValues - z_low) == z1);	ind2 = find(abs(zValues - z_high) == z2);	ind1 = ind1(1);	ind2 = ind2(1);		slice1 = min([ind1,ind2]);	slice2 = max([ind1,ind2]);		%Now get associated x, y, and z points:		%Get corner points:	[x1,y1,z1] = mtoxyz(max(rV),min(cV),slice1,planC);	[x2,y2,z2] = mtoxyz(min(rV),min(cV),slice1,planC);	[x3,y3,z3] = mtoxyz(min(rV),max(cV),slice1,planC);	[x4,y4,z4] = mtoxyz(max(rV),max(cV),slice1,planC);		[x5,y5,z5] = mtoxyz(max(rV),min(cV),slice2,planC);	[x6,y6,z6] = mtoxyz(min(rV),min(cV),slice2,planC);	[x7,y7,z7] = mtoxyz(min(rV),max(cV),slice2,planC);	[x8,y8,z8] = mtoxyz(max(rV),max(cV),slice2,planC);		%Get delta's	delta = planC{indexS.scan}.scanInfo(1).grid1Units;		resolutionFactor = round(resolution / delta);	resolutionFactor = resolutionFactor * [resolutionFactor > 0] + [resolutionFactor == 0];  %No less than one.		xV = x1 : delta * resolutionFactor : x3;	yV = y1 : delta * resolutionFactor : y2;	zV = zValues(slice1:slice2);  %Could be nonuniform in z.end[x3M, y3M, z3M] = meshgrid(xV, yV, zV);[cM, rM, sM] = meshgrid(1:length(xV), length(yV): -1 :1, 1:length(zV)); %Corresponding indicesdisp('Get distances...')%Now get the distance from each one of these points to the surface points.dist3M = zeros(size(x3M));disp(['Number of surface points is: ' num2str(length(xSurfV))])h = waitbar(0,'Constructing distance transform and dose map...');iMax = length(x3M(:));surfacePoints = [xSurfV ySurfV zSurfV]';for i  = 1 : iMax%    rTmpSq = (x3M(i) - xSurfV).^2 +  (y3M(i)-ySurfV).^2 +  (z3M(i)-zSurfV).^2;  rTmpSq = sepsq(surfacePoints, [x3M(i);y3M(i);z3M(i)]);    rSq = min(rTmpSq);  dist3M(rM(i),cM(i),sM(i)) = rSq^0.5;  if rem(i,100) == 0    waitbar(i/iMax,h)endendclose(h)[mask3MU, zValues] = getMask3D(structNum,planC);[xVU, yVU, zVU] = getScanXYZVals(planC{indexS.scan}(stateS.currentScan));[xVUMesh, yVUMesh, zVUMesh] = meshgrid(xVU, yVU, zVU);interior = interp3(xVUMesh, yVUMesh, zVUMesh, double(mask3MU), x3M, y3M, z3M);interior = interior > .5;dist3M(interior) = -dist3M(interior);