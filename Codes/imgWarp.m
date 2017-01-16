function [outputImg, corner] = imgWarp(inputImg, params, method)
%% Warp input image according to different 2D transformation models
% Developed by He Sun and Irene Fan on Jan. 15
% inputImg: input image before warpping
% params: parameters that define the 2D transforamtion model
% method: 'Translation', 'Rigid', 'Affine' or 'Homography'

% Bilinearly interpolate is used in this function

%% Find the corner location after transformation
topLeft = transformInv([1, 1], params, method);
topRight = transformInv([size(inputImg, 2), 1], params, method);
bottomLeft = transformInv([1, size(inputImg, 1)], params, method);
bottomRight = transformInv([size(inputImg, 2), size(inputImg, 1)], params, method);
minX = ceil(min(topLeft(1), bottomLeft(1)));
maxX = floor(max(topRight(1), bottomRight(1)));
minY = ceil(min(topLeft(2), topRight(2)));
maxY = floor(max(bottomLeft(2), bottomLeft(2)));

corner = [minX, maxX, minY, maxY];
%% Define the size of image according to the corner location
sizeX = maxX - minX + 1;
sizeY = maxY - minY + 1;

outputImg = zeros(sizeY, sizeX, size(inputImg, 3));
outputImg = uint8(outputImg);

inputImgDouble = double(inputImg);
%% Transform each pixel in the input image into the output image
for xWarp = minX : maxX
    for yWarp = minY : maxY
        % Compute the new location of pixel (x, y) after transformation
        temp = transform([xWarp, yWarp], params, method);
        
        % Bilinearly interpolate
        x = temp(1);
        y = temp(2);
        
        xl = floor(x);
        yl = floor(y);
        
        xu = xl + 1;
        yu = yl + 1;
        
        fracTL = (x - xl) * (y - yl);
        fracTR = (xu - x) * (y - yl);
        fracBL = (x - xl) * (yu - y);
        fracBR = (xu - x) * (yu - y);
        
        if xl > 0 && yl > 0 && xu <= size(inputImg, 2) && yu <= size(inputImg, 1)
            temp = fracTL * inputImgDouble(yl, xl, :) + fracTR * inputImgDouble(yl, xu, :)...
                + fracBL * inputImgDouble(yu, xl, :) + fracBR * inputImgDouble(yu, xu, :);
            outputImg(yWarp - minY + 1, xWarp - minX + 1,:) = uint8(temp);
        end
    
    end
end

clear inputImgDouble;
end
