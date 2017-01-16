function x = transformInv(x_new, params, method)
%% Define different 2D inverse transformation models
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
        x = affineInv(x_new, params);
    case 'translation'
        x = translationInv(x_new, params);
    case 'homography'
        x = homographyInv(x_new, params);
    otherwise
        disp('We do not have the method you indicate. Please choose from:');
        disp('Translation, Rigid, Affine, Homography');
end

end

function x = affineInv(x_new, params)
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
x = (x_new - repmat(T', [size(x_new, 1), 1])) * (R')^(-1);

end

function x = translationInv(x_new, params)

% Calculate the translation transformation
x = x_new - repmat(params', [size(x_new, 1), 1]);

end

function x = homographyInv(x_new, params)
    
    a = params(1);
    b = params(2);
    c = params(3);
    d = params(4);
    e = params(5);
    f = params(6);
    g = params(7);
    h = params(8);
    i = params(9);
    x = x_new;
    
    for itr = 1 : size(x_new, 1)
        x_new_now = x_new(itr, :);
        H = [a - g * x_new_now(1), b - h * x_new_now(1);
            d - g * x_new_now(2), e - h * x_new_now(2)];
        z = [i * x_new_now(1) - c; i * x_new_now(2) - f];
        temp = H^(-1) * z;
        x(itr, :) = temp';
    end
    
end