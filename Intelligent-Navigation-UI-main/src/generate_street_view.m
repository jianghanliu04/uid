function streetImg = generate_street_view(mapImage, centreR, centreC, roadAngle, mapHeight, scale)
%GENERATE_STREET_VIEW Improved pseudo-3D rendering with corrected perspective curves.

    outH = 400; outW = 500;
    streetImg = uint8(zeros(outH, outW, 3));

    viewLength = 150;      % Max look-ahead distance in meters
    viewWidth  = 60;       % Field of view width at horizon

    skyH = round(outH * 0.4);
    for row = 1:skyH
        t = (row-1)/skyH;
        streetImg(row,:,1) = uint8(100 + 80*t);
        streetImg(row,:,2) = uint8(140 + 60*t);
        streetImg(row,:,3) = uint8(220 + 20*t);
    end

    groundH = outH - skyH;
    [wx0, wy0] = pixel_to_world(centreR, centreC, mapHeight, scale);
    angRad = roadAngle * pi / 180;
    cosA = cos(angRad); sinA = sin(angRad);
    [imgH, imgW, ~] = size(mapImage);

    for gRow = 1:groundH
        outRow = skyH + gRow;
        % Quadratic t for more realistic perspective (compresses horizon)
        t = (gRow / groundH)^1.8; 
        dist = viewLength * (1 - t) + 1.0; % +1.0 to avoid being exactly at the camera
        
        currentWidth = viewWidth * (1 - t * 0.8);
        colIdx = 1:outW;
        frac = (colIdx / outW) - 0.5;
        lateral = frac * currentWidth;

        wxArr = wx0 + dist * cosA - lateral * sinA;
        wyArr = wy0 + dist * sinA + lateral * cosA;

        prArr = round(mapHeight - wyArr/scale + 0.5);
        pcArr = round(wxArr/scale + 0.5);

        valid = prArr >= 1 & prArr <= imgH & pcArr >= 1 & pcArr <= imgW;
        vIdx = find(valid);
        if ~isempty(vIdx)
            for ch = 1:3
                chan = mapImage(:,:,ch);
                pixVals = chan(prArr(vIdx) + (pcArr(vIdx)-1)*imgH);
                % Apply basic distance shading
                shade = 0.5 + 0.5 * t;
                tmp = streetImg(outRow,:,ch);
                tmp(vIdx) = uint8(double(pixVals) * shade);
                streetImg(outRow,:,ch) = tmp;
            end
        end
    end
end