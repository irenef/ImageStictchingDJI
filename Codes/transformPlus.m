function paramsNew = transformPlus(params1, params2, method)
%% Define plus for different 2D transformation models
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
        paramsNew = affinePlus(params1, params2);
    case 'translation'
        paramsNew = translationPlus(params1, params2);
    case 'homography'
        paramsNew = homographyPlus(params1, params2);
    otherwise
        disp('We do not have the method you indicate. Please choose from:');
        disp('Translation, Rigid, Affine, Homography');
end

end

function paramsNew = affinePlus(params1, params2)

a = params1(1);
b = params1(2);
tx = params1(3);
c = params1(4);
d = params1(5);
ty = params1(6);

R1 = [a, b; c, d];
T1 = [tx; ty];

a = params2(1);
b = params2(2);
tx = params2(3);
c = params2(4);
d = params2(5);
ty = params2(6);

R2 = [a, b; c, d];
T2 = [tx; ty];

Rplus = R2 * R1;
Tplus = R2 * T1 + T2;

paramsNew = [Rplus(1,1); Rplus(1,2); Tplus(1); Rplus(2,1); Rplus(2,2); Tplus(2)];

end

function paramsNew = translationPlus(params1, params2)

paramsNew = params1 + params2;

end

function paramsNew = homographyPlus(params1, params2)

a = params1(1);
b = params1(2);
c = params1(3);
d = params1(4);
e = params1(5);
f = params1(6);
g = params1(7);
h = params1(8);
i = params1(9);

T1 = [a, b, c; d, e, f; g, h, i];

a = params2(1);
b = params2(2);
c = params2(3);
d = params2(4);
e = params2(5);
f = params2(6);
g = params2(7);
h = params2(8);
i = params2(9);

T2 = [a, b, c; d, e, f; g, h, i];

T3 = T1 * T2;

paramsNew = [T3(1,1), T3(1,2), T3(1,3), T3(2,1), T3(2,2), T3(2,3), ...
    T3(3,1), T3(3,2), T3(3,3)];

end