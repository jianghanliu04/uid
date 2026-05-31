function h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter)
%DRAW_IV Standard Scale Version.

    palette = [0.3 0.6 1.0; 1.0 0.4 0.4; 0.3 0.8 0.4; 1.0 0.7 0.2];
    cidx = mod(iv.ID - 1, size(palette, 1)) + 1;
    faceClr = palette(cidx, :);

    halfL = (iv.Length * iv.ScaleFactor) / 2;
    halfW = (iv.Width  * iv.ScaleFactor) / 2;

    % Local wedge shape
    local = [-halfL, -halfW;
              halfL*0.4, -halfW;
              halfL*1.5,  0;       
              halfL*0.4,  halfW;
             -halfL,  halfW];

    iv_rad = iv.Angle * pi / 180;
    cosA = cos(iv_rad); sinA = sin(iv_rad);
    worldC = zeros(5, 2);
    for k = 1:5
        worldC(k,1) = iv.WorldX + cosA * local(k,1) - sinA * local(k,2);
        worldC(k,2) = iv.WorldY + sinA * local(k,1) + cosA * local(k,2);
    end

    pixC = zeros(5,1); pixR = zeros(5,1);
    for k = 1:5
        [pixR(k), pixC(k)] = world_to_pixel(worldC(k,1), worldC(k,2), mapHeight, scale);
    end
    [centR, centC] = world_to_pixel(iv.WorldX, iv.WorldY, mapHeight, scale);

    if abs(rotAngle) > 0.001
        mapRad = rotAngle * pi / 180;
        cosM = cos(mapRad); sinM = sin(mapRad);
        for k = 1:5
            dc = pixC(k)-origCenter(1); dr = pixR(k)-origCenter(2);
            pixC(k) = cosM*dc + sinM*dr + rotCenter(1);
            pixR(k) = -sinM*dc + cosM*dr + rotCenter(2);
        end
        dc = centC-origCenter(1); dr = centR-origCenter(2);
        centC = cosM*dc + sinM*dr + rotCenter(1);
        centR = -sinM*dc + cosM*dr + rotCenter(2);
    end

    h1 = patch(ax, pixC, pixR, faceClr, 'FaceAlpha', 0.85, 'EdgeColor', [1 1 0.4], 'LineWidth', 1.5);
    h2 = text(ax, centC, centR - 15, sprintf('#%d', iv.ID), 'Color', 'w', ...
        'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0 0 0 0.5]);

    h = [h1; h2];
end