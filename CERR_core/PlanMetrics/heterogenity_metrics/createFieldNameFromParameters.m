function fieldName = createFieldNameFromParameters(imageType,settingS)
% createFieldNamesFromParameters(imageType,settingS)
%
% Create unique fieldname for radiomics features returned by
% calcRadiomicsForImgType
%
% -------------------------------------------------------------------------
% INPUTS
% imageType : 'Original' or filtered image type (see processImage.m for valid options)
% settingS  : Parameter dictionary for radiomics feature extraction
% -------------------------------------------------------------------------
%
% AI 4/2/19

%settingS = paramS.imageType.(imageType);

switch(lower(imageType))
    
    case {'original','sobel'}
        fieldName = imageType;
        
    case 'haralickcooccurance'
        dirC = {'3d','2d'};
        dir = dirC{settingS.Directionality.val};
        settingsStr = [settingS.Type.val,'_',dir,'_',...
            num2str(settingS.NumLevels.val),'levels_patchsize',...
            num2str(settingS.PatchSize.val(1)),num2str(settingS.PatchSize.val(2)),...
            num2str(settingS.PatchSize.val(3))];
        fieldName = [imageType,'_',settingsStr];
        
    case 'wavelets'
        settingsStr = [settingS.Wavelets.val,'_',num2str(settingS.Index.val),'_',settingS.Direction.val];
        fieldName = [imageType,'_',settingsStr];
        
    case 'log'
        settingsStr = ['sigma_',num2str(settingS.Sigma_mm.val),'mm'];
        fieldName = [imageType,'_',settingsStr];
        
    case 'gabor_deprecated'
        settingsStr = ['radius',num2str(settingS.Radius.val),'_sigma',...
            num2str(settingS.Sigma.val),'_AR',num2str(settingS.AspectRatio.val),...
            '_',num2str(settingS.Orientation.val),'_deg_wavelength',...
            num2str(settingS.Wavlength.val)];
        fieldName = [imageType,'_',settingsStr];
        
    case 'gabor'
        settingsStr = ['voxSz',num2str(settingS.VoxelSize_mm.val),'mm_Sigma',...
            num2str(settingS.Sigma_mm.val),'mm_AR',num2str(settingS.SpatialAspectRatio.val),...
            '_wavLen',num2str(settingS.Wavlength_mm.val),'mm'];
        thetaV = reshape(settingS.Orientation.val,1,[]);
        if length(thetaV)==1
            settingsStr = [settingsStr,'_Orient',num2str(thetaV)];
        else
            settingsStr = [settingsStr,'_OrientAvg_',num2str(thetaV)];
            fieldName = [imageType,'_',settingsStr];
        end
        
        
    case 'firstorderstatistics'
        settingsStr = ['patchsize',num2str(settingS.PatchSize.val(1)),...
            '_voxelvol',num2str(settingS.VoxelVolume.val)];
        fieldName = ['firstOrderStatistics','_',settingsStr];
        
    case 'lawsconvolution'
        dirC = {'2d','3d'};
        settingsStr = [dirC{settingS.Direction.val},'_kernelSize',...
            num2str(settingS.KernelSize.val)];
        fieldName = [imageType,'_',settingsStr];
        
    case 'collage'
        settingsStr = [settingS.Dimension.val,'_',...
            num2str(settingS.Number_Gray_Levels.val),'bins_','dominantRadius'...
            num2str(settingS.Dominant_Dir_Radius.val(1)),'_cooccurRadius',...
            num2str(settingS.Cooccur_Radius.val(1))];
        fieldName = [imageType,'_',settingsStr];
        
    case 'simpleitk'
        sitkFilter = settingS.sitkFilterName.val;
        switch lower(sitkFilter)
            case 'laplacianrecursivegaussianimagefilter'
                settingsStr = ['sigma_mm_',num2str(settingS.Sigma_mm.val)];
                sitkFilter = 'LaplacianRecursiveGauss';
            case 'n4biasandhistogramcorrectionimagefilter'
                settingsStr = ['numFitLev_',num2str(settingS.numFittingLevels.val)];
                sitkFilter = 'N4plusHistMatch';
            case 'histogrammatchingimagefilter'
                settingsStr = ['numHistLev_',num2str(settingS.numHistLevel.val),...
                    '_numMatchPts_',num2str(settingS.numMatchPts.val)];
                sitkFilter = 'HistMatch';
            case 'n4biasfieldcorrectionimagefilter'
                settingsStr = ['numFitLev_',num2str(settingS.numFittingLevels.val)];
                sitkFilter = 'N4Bias';
        end        
        fieldName = [imageType,'_',sitkFilter,'_',settingsStr];
        
    case 'suv'
        suvType = settingS.suvType.val;
        fieldName = [imageType,'_',suvType];
        
end

%Ensure valid fieldname
fieldName = strrep(fieldName,' ','');
fieldName = strrep(fieldName,'.','_');

end