function tforms = InitializeTransform(n, method)

switch lower(method)
    case 'affine'
        fixTform = [1, 0, 0, 0, 1, 0];
    case 'translation'
        fixTform = [0, 0];
    case 'homography'
        fixTform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
    otherwise
        disp('We do not have the method you indicate. Please choose from:');
        disp('Translation, Rigid, Affine, Homography');
end
tforms = repmat(fixTform, [n, 1]);

end
