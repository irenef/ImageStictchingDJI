%% Feature Based Image Stitching
% This is the main file for multiple images stitching of UAV images.
% Developed by He Sun and Irene Fan on Jan. 15, 2017, part of codes are
% adapted from MATLAB built-in file 'FeatureBasedPanoramicImageStitchingExample.m'

%% Overview
% There are 5 main steps in feature based image stitching:
% 1 Find keypoints and compute image descriptors;
% 2 Generate candidate keypoint matches;
% 3 Use RANSAC to find best image transformation;
% 4 Warp images according to transformation;
% 5 Blend images in overlapping regions;
%
% In this project, the step 1 and 2 are accomplished using matlab
% built-in functions to calculate SURF descriptor and find matches.
% Different Affine methods are implemented in Step 3 and 4, and several
% blending methods are tested and implementted in Step 5.

%% Step 0 - Load Images
clear all; close all
% Load images.
% Change to the right repository before running the codes.
Dir = 'C:\Users\hesun\Google Drive\Course\CoputerVision\ImageStictchingDJI\Images';
Scene = imageSet(Dir);

% Display images to be stitched
montage(Scene.ImageLocation)

%% Step 1.1 - Initialization and find keypoints and compute image descriptors of the first image

% Read the first image from the image set and resize image to appropriate
% size.
I = read(Scene, 1);
I = imresize(I, [400, 300]);

% Detect the SURF feature for the 1st image.
grayImage = rgb2gray(I);
points = detectSURFFeatures(grayImage);
[features, points] = extractFeatures(grayImage, points);

% Define the translation model
method = 'Homography';%'Translation','Affine' or 'Homography';

% Initialize the tranform between images based on tranformation method.
tforms = InitializeTransform(Scene.Count, method);

%% Begin loop to find tranform between neighboring images
for itrImg = 2 : Scene.Count

    %% Step 1.2 - Find keypoints and compute image descriptors
    
    % Store points and features for prevoius images
    pointsPrevious = points;
    featuresPrevious = features;

    % Read the current image and resize image to appropriate size
    I = read(Scene, itrImg);
    I = imresize(I, [400, 300]);

    % Detect the SURF feature for the current images
    grayImage = rgb2gray(I);
    points = detectSURFFeatures(grayImage);
    [features, points] = extractFeatures(grayImage, points);

    %% Step 2 - Generate candidate keypoint match

    indexPairs = matchFeatures(features, featuresPrevious, 'Unique', true);
    matchedPoints = points(indexPairs(:,1), :);
    matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);

    %% Step 3 - Use RANSAC to find best image transformation

    % Define the tuning paramerters and termination conditions for RANSAC
    % algorithm
    numMatches = size(indexPairs, 1);
    maxInliers = 0;
    epsilon = 5;
    numItr = 100000;
    percentSample = 0.2;
    numSample = ceil(percentSample * numMatches);
    largestSet = [];
    bestParams = [];

    % Iterate to find the largest set of inliers
    for itr = 1 : numItr

        % Random select samples
        sampleIndex = randperm(numMatches, numSample);
        sampleMatchedPoints = matchedPoints(sampleIndex, :);
        sampleMatchedPointsPrev = matchedPointsPrev(sampleIndex, :);

        % Construct the regression matrix according to transformation method
        % We only consider affine now

        sampleLocations = sampleMatchedPoints.Location;
        sampleLocationsPrev = sampleMatchedPointsPrev.Location;
        
        % Compute the z and H according to translation model
        switch lower(method)
            case 'affine'
                z = [sampleLocations(:,1); sampleLocations(:,2)];
                H = [sampleLocationsPrev, ones(numSample, 1), zeros(numSample, 3); 
                    zeros(numSample, 3), sampleLocationsPrev, ones(numSample, 1)];
            case 'translation'
                z = [sampleLocations(:,1) - sampleLocationsPrev(:,1); ...
                    sampleLocations(:,2) - sampleLocationsPrev(:,2)];
                H = [ones(numSample, 1), zeros(numSample, 1);
                    zeros(numSample, 1), ones(numSample, 1)];
            case 'homography'
                H = [-sampleLocationsPrev, ones(numSample, 1), zeros(numSample, 3), ...
                    repmat(sampleLocations(:, 1), [1, 3]) .* [sampleLocationsPrev, ones(numSample, 1)];
                    zeros(numSample, 3), -sampleLocationsPrev, ones(numSample, 1), ...
                    repmat(sampleLocations(:, 2), [1, 3]) .* [sampleLocationsPrev, ones(numSample, 1)]];
            otherwise
                disp('We do not have the method you indicate. Please choose from:');
                disp('Translation, Rigid, Affine, Homography');
        end
        
        % Compute the parameters for the transformation
        switch lower(method)
            case 'homography'
                [V, D] = eig(H' * H);
                [eigenSorted, eigenInd] = sort(diag(D), 'ascend');
                params = V(:, eigenInd(1));
                
            otherwise
                % Least square regression to calculate the paramters
                params = (H' * H)^(-1) * H' * z;
        end
        
        % Compute the predicted locations based on calculated parameters
                locationsPred = transform(matchedPointsPrev.Location, params, method);

                % Compute the inliers where sum of squre difference between prediction
                % and the true value is smaller than threshold
                SSD = sum((locationsPred - matchedPoints.Location).^2, 2);
                indexInliers = find(SSD < epsilon);
                numInliers = length(indexInliers);
                
        % Record the largest set of inliers so far and corresponding best
        % parameters
        if numInliers > maxInliers
            maxInliers = numInliers;
            bestParams = params;
            largestSet = indexInliers;
        end
        
    end

    % Re-compute the parameters using all the members in the consensus set

    ConsensusMatchedPoints = matchedPoints(largestSet, :);
    ConsensusMatchedPointsPrev = matchedPointsPrev(largestSet, :);

    % Construct the regression matrix according to transformation method

    ConsensusLocations = ConsensusMatchedPoints.Location;
    ConsensusLocationsPrev = ConsensusMatchedPointsPrev.Location;
    
    switch lower(method)
        case 'affine'
            z = [ConsensusLocations(:,1); ConsensusLocations(:,2)];
            H = [ConsensusLocationsPrev, ones(maxInliers, 1), zeros(maxInliers, 3); 
                zeros(maxInliers, 3), ConsensusLocationsPrev, ones(maxInliers, 1)];
        case 'translation'
            z = [ConsensusLocations(:,1) - ConsensusLocationsPrev(:,1); ...
                ConsensusLocations(:,2) - ConsensusLocationsPrev(:,2)];
            H = [ones(maxInliers, 1), zeros(maxInliers, 1);
                zeros(maxInliers, 1), ones(maxInliers, 1)];
        case 'homography'
            H = [-ConsensusLocationsPrev, ones(maxInliers, 1), zeros(maxInliers, 3), ...
                repmat(ConsensusLocations(:, 1), [1, 3]) .* [ConsensusLocationsPrev, ones(maxInliers, 1)];
                zeros(maxInliers, 3), -ConsensusLocationsPrev, ones(maxInliers, 1), ...
                repmat(ConsensusLocations(:, 2), [1, 3]) .* [ConsensusLocationsPrev, ones(maxInliers, 1)]];
        otherwise
            disp('We do not have the method you indicate. Please choose from:');
            disp('Translation, Rigid, Affine, Homography');
    end

    % Compute the parameters for the transformation
    switch lower(method)
        case 'homography'
%             [V, D] = eig(H' * H);
%             [eignSorted, eigenInd] = sort(diag(D), 'ascend');
%             params = V(:, eigenInd(1));
            params = bestParams;
        otherwise
            params = (H' * H)^(-1) * H' * z;
    end
    

    % Find the plus of current tranform and previous transform
    paramsPlus = transformPlus((tforms(itrImg-1,:))', params, method);
    tforms(itrImg,:) = paramsPlus';
end
%%
%% Step 4 - Warp images according to transformation

% Reload the original images
I = cell(Scene.Count,1);
for itrImg = 1 : Scene.Count
    Itemp = read(Scene, itrImg);
    I{itrImg} = imresize(Itemp, [400, 300]);
end

% Warp the images according to the transform
Iwarp = cell(Scene.Count,1);
limit = zeros(Scene.Count, 4);
Iwarp{1} = I{1};
limit(1,:) = [1, size(I{1}, 2), 1, size(I{1}, 1)];
for itrImg = 2 : Scene.Count
    params = (tforms(itrImg, :))';
    [Itemp, corner] = imgWarp(I{itrImg}, params, method);
    Iwarp{itrImg} = Itemp;
    limit(itrImg, :) = corner;
end
%% Step 5 - Blend images in overlapping regions
Iwarp_new = cell(Scene.Count,1);
Iwarp_new{2} = Iwarp{1};
Iwarp_new{1} = Iwarp{2};
limit_new = limit;
limit_new(1,:) = limit(2,:);
limit_new(2,:) = limit(1,:);
blendMethod = 'firstOccupy';
panoramaView = panorama(Iwarp_new, limit_new, blendMethod);
% panoramaView = panorama(Iwarp, limit, blendMethod);
figure, imshow(panoramaView);