function x_new = transform(x, params, method)
%% Define different 2D transformation models
% Developed by He Sun and Irene Fan on Jan. 15
% x_new: coordinate after transformation
% x: coordinate before transformation
% method: string to define different transformation models
%   'Translation': x' = x + tx, y' = y + ty;
%   'Rigid': x' = x cos(theta) - y sin(theta) + tx, 
%            y' = x sin(theta) - y cos(theta) + ty;
%   'Affine': x' = a x + b y + tx;, y' = c x + d y + ty;
%   'Homography':

switch lower(method)
    case 'affine'
        x_new = affine(x, params);
    case 'translation'
        x_new = translation(x, params);
    case 'homography'
        x_new = homography(x, params);
    otherwise
        disp('We do not have the method you indicate. Please choose from:');
        disp('Translation, Rigid, Affine, Homography');
end

end

function x_new = affine(x, params)
    % Define the coefficients
    
    a = params(1);
    b = params(2);
    tx = params(3);
    c = params(4);
    d = params(5);
    ty = params(6);
    
    R = [a, b; c, d];
    T = [tx; ty];
    
    % Calculate the affine transformation
    x_new = x * R' + repmat(T', [size(x, 1), 1]);
end

function x_new = translation(x, params)
    % Define the coefficients
    tx = params(1);
    ty = params(2);
    
    T = [tx; ty];
    
    % Calculate the affine transformation
    x_new = x + repmat(T', [size(x, 1), 1]);
end

function x_new = homography(x, params)

scale = x * params(7:8, :) + params(9);
x_new(:, 1) = (x * params(1:2, :) + params(3)) ./ scale;
x_new(:, 2) = (x * params(4:5, :) + params(6)) ./ scale;

end