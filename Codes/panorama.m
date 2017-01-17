function outputImg = panorama(Iwarp, limit, blendMethod)
%% Blend images in overlapping regions to construct panorama
% outputImg: out put panorama images
% Iwarp: input images after warping
% limit: the corner coordinates of input images
% method: the translation model, including 'firstoccupy', 'average', 'DP',
% 'melting' and 'quilting'

switch lower(blendMethod)
    case 'firstoccupy'
        outputImg = panoramaFirstOccupy(Iwarp, limit);
    otherwise
        disp('We do not have the method you indicate. Please choose from:');
        disp('firstOccupy, average, DP, melting and quilting');
end


end

function panoramaView = panoramaFirstOccupy(Iwarp, limit)

range = [min(limit(:,1)), max(limit(:,2)), min(limit(:,3)), max(limit(:,4))];

panoramaView = uint8(zeros(range(4) - range(3) + 1, range(2)-range(1)+1, 3));
panoramaMask = uint8(ones(size(panoramaView)));

for itr = 1 : length(Iwarp)
    panoramaViewNow = 0 * panoramaView;
%     panoramaViewNow(range(4)-limit(itr,4)+1 : range(4) - limit(itr,3)+1, ...
    panoramaViewNow(limit(itr,3)-range(3)+1 : limit(itr,4)-range(3)+1, ...
    limit(itr,1)-range(1)+1 : limit(itr,2)-range(1)+1, :) = Iwarp{itr};
    panoramaView = panoramaView + panoramaMask .* panoramaViewNow;
    panoramaMask = uint8(1 - (panoramaView > 0));
end

end