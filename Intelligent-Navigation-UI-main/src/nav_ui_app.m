function app = nav_ui_app(projectRoot)
%NAV_UI_APP  ISE 333 - Perfect Integration Version.
%   Features: Original OR Layout (with scroll arrows), Continuous Add, 
%   Correct Coordinate Display, Additive Rotation, and Persistence.

% =====================================================================
%  1.  LOAD RESOURCES
% =====================================================================
    mapPath  = fullfile(projectRoot, 'MapForUI.jpg');
    mapImage = imread(mapPath);
    [mapH, mapW, ~] = size(mapImage);
    roadMask = build_road_mask(mapImage);

    C.BD = [0.18 0.20 0.25]; C.BP = [0.22 0.24 0.30];
    C.BB = [0.35 0.38 0.48]; C.BA = [0.25 0.55 0.85];
    C.FL = [0.85 0.88 0.95]; C.FO = [0.55 0.85 0.60];
    C.FS = [0.60 0.63 0.75]; C.ERR = [1.0 0.4 0.4];
    FN = 'Segoe UI';

% =====================================================================
%  2.  FIGURE
% =====================================================================
    ss = get(0,'ScreenSize');
    fw = min(1400, ss(3)*0.88); fh = min(900, ss(4)*0.88);
    fig = figure('Name','Intelligent Navigation UI', 'NumberTitle','off', ...
        'Color',C.BD,'MenuBar','none','ToolBar','none', ...
        'Position',[(ss(3)-fw)/2 (ss(4)-fh)/2 fw fh]);

% =====================================================================
%  3.  UI LAYOUT (Optimized heights for non-clipping)
% =====================================================================
    mp = uipanel('Parent',fig,'Units','normalized','Position',[0.005 0.06 0.685 0.935],'BackgroundColor',C.BD,'BorderType','none');
    mapAx = axes('Parent',mp,'Units','normalized','Position',[0.01 0.01 0.98 0.98],'Color',[0 0 0]);
    hImg = imshow(mapImage,'Parent',mapAx);

    rp = uipanel('Parent',fig,'Units','normalized','Position',[0.695 0.06 0.30 0.935],'BackgroundColor',C.BP,'BorderType','none');

    % Mode & Coord
    modeL = uicontrol('Parent',rp,'Style','text','Units','normalized','Position',[0.03 0.96 0.94 0.035],...
        'String','Mode: Idle','FontName',FN,'FontSize',12,'FontWeight','bold','BackgroundColor',C.BP,'ForegroundColor',C.FO);
    lab(rp,[0.03 0.935 0.94 0.022],'COORD (X, Y in meters):',FN,C.BP,C.FS);
    coordDisplay = uicontrol('Parent',rp,'Style','text','Units','normalized','Position',[0.03 0.885 0.94 0.045],...
        'String','X: -- m, Y: -- m','FontName',FN,'FontSize',14,'FontWeight','bold','BackgroundColor',[.15 .17 .22],'ForegroundColor',[1 1 .6]);

    % VEHICLE CONTROLS
    sep(rp,0.875,C.BB); stit(rp,0.855,'VEHICLE CONTROLS',FN,C.BP,C.FS);
    lab(rp,[0.03 0.825 0.28 0.022],'Heading:',FN,C.BP,C.FL);
    angIn = uicontrol('Parent',rp,'Style','edit','Units','normalized','Position',[0.32 0.825 0.14 0.022],'String','0');
    lab(rp,[0.50 0.825 0.18 0.022],'Scale:',FN,C.BP,C.FL);
    scIn = uicontrol('Parent',rp,'Style','edit','Units','normalized','Position',[0.68 0.825 0.14 0.022],'String','1.5'); 
    btn(rp,[0.03 0.79 0.30 0.028],'Add IV',FN,C.BA,[1 1 1],@(~,~)onAddIV(fig));
    btn(rp,[0.35 0.79 0.30 0.028],'Remove IV',FN,[.7 .3 .3],[1 1 1],@(~,~)onRemoveIV(fig));
    btn(rp,[0.67 0.79 0.30 0.028],'Report All',FN,C.BB,[1 1 1],@(~,~)onReportIV(fig));
    ivLB = uicontrol('Parent',rp,'Style','listbox','Units','normalized','Position',[0.03 0.70 0.94 0.08],...
        'String',{'(none)'},'FontSize',9,'BackgroundColor',[.28 .30 .36],'ForegroundColor',[.9 .9 .95],'Callback',@(~,~)updateLocalView(fig));

    % MEASUREMENT
    sep(rp,0.69,C.BB); stit(rp,0.67,'MEASUREMENT',FN,C.BP,C.FS);
    btn(rp,[0.03 0.63 0.30 0.028],'Distance',FN,C.BB,[1 1 1],@(~,~)onDistBtn(fig));
    btn(rp,[0.35 0.63 0.30 0.028],'Trajectory',FN,C.BB,[1 1 1],@(~,~)onTrajBtn(fig));
    btn(rp,[0.67 0.63 0.30 0.028],'Clear',FN,C.BB,[1 1 1],@(~,~)onClearMeas(fig));
    dR = uicontrol('Parent',rp,'Style','text','Units','normalized','Position',[0.03 0.605 0.45 0.022],'String','Dist: --','BackgroundColor',C.BP,'ForegroundColor',C.FL);
    tR = uicontrol('Parent',rp,'Style','text','Units','normalized','Position',[0.50 0.605 0.47 0.022],'String','Traj: --','BackgroundColor',C.BP,'ForegroundColor',C.FL);

    % MAP ROTATION (Fixed alignment and space)
    sep(rp,0.595,C.BB); stit(rp,0.575,'MAP ROTATION (Additive CCW)',FN,C.BP,C.FS);
    lab(rp,[0.03 0.54 0.32 0.025],'Step Ang:',FN,C.BP,C.FL);
    rotIn = uicontrol('Parent',rp,'Style','edit','Units','normalized','Position',[0.36 0.54 0.14 0.025],'String','90');
    btn(rp,[0.52 0.537 0.22 0.030],'Rotate',FN,C.BA,[1 1 1],@(~,~)onRotate(fig));
    btn(rp,[0.75 0.537 0.22 0.030],'Reset',FN,C.BB,[1 1 1],@(~,~)onResetView(fig));

% =====================================================================
%  4.  RESTORED ORIGINAL OR TABS (With scroll arrows)
% =====================================================================
    sep(rp,0.525,C.BB); stit(rp,0.505,'OPTIONAL FEATURES',FN,C.BP,C.FS);
    tg = uitabgroup('Parent',rp,'Units','normalized','Position',[0.02 0.01 0.96 0.49]);

    % OR1: Skeleton
    t1 = uitab(tg,'Title','OR1:Skeleton','BackgroundColor',C.BP);
    btn(t1,[0.03 0.90 0.30 0.07],'Extract',FN,C.BA,[1 1 1],@(~,~)onSkelExtract(fig));
    btn(t1,[0.35 0.90 0.30 0.07],'End',FN,C.BB,[1 1 1],@(~,~)onSkelEnd(fig));
    btn(t1,[0.67 0.90 0.30 0.07],'Clear',FN,[.6 .3 .3],[1 1 1],@(~,~)onSkelClear(fig));
    btn(t1,[0.03 0.82 0.46 0.07],'Show Skeleton',FN,C.BB,[1 1 1],@(~,~)onSkelShow(fig));
    btn(t1,[0.51 0.82 0.46 0.07],'Show Road Area',FN,C.BB,[1 1 1],@(~,~)onSkelRoadArea(fig));
    skelInfo = uicontrol('Parent',t1,'Style','text','Units','normalized','Position',[0.03 0.76 0.94 0.05],'String','Points: 0','BackgroundColor',C.BP,'ForegroundColor',C.FL);
    skelAx = axes('Parent',t1,'Units','normalized','Position',[0.05 0.03 0.90 0.72],'Color',[.1 .1 .14]); axis(skelAx,'off');

    % OR2: LocalView
    t2 = uitab(tg,'Title','OR2:LocalView','BackgroundColor',C.BP);
    lab(t2,[0.03 0.92 0.28 0.06],'Range(m):',FN,C.BP,C.FL);
    rgIn = uicontrol('Parent',t2,'Style','edit','Units','normalized','Position',[0.32 0.92 0.18 0.06],'String','100');
    btn(t2,[0.53 0.92 0.44 0.06],'Update View',FN,C.BB,[1 1 1],@(~,~)updateLocalView(fig));
    locAx = axes('Parent',t2,'Units','normalized','Position',[0.05 0.03 0.90 0.87],'Color',[.1 .1 .14]); axis(locAx,'off');

    % OR3: AutoAlign
    t3 = uitab(tg,'Title','OR3:AutoAlign','BackgroundColor',C.BP);
    btn(t3,[0.03 0.90 0.94 0.08],'Auto-Add IV (PCA)',FN,C.BA,[1 1 1],@(~,~)onAutoAddIV(fig));
    btn(t3,[0.03 0.80 0.46 0.08],'Head-Up View',FN,C.BB,[1 1 1],@(~,~)onHeadUp(fig));
    btn(t3,[0.51 0.80 0.46 0.08],'Normal View',FN,C.BB,[1 1 1],@(~,~)onResetView(fig));

    % OR4: StreetView
    t4 = uitab(tg,'Title','OR4:StreetView','BackgroundColor',C.BP);
    btn(t4,[0.03 0.92 0.94 0.06],'Generate Street View',FN,C.BA,[1 1 1],@(~,~)onStreetViewBtn(fig));
    svAx = axes('Parent',t4,'Units','normalized','Position',[0.03 0.03 0.94 0.87],'Color',[.1 .1 .14]); axis(svAx,'off');

    % OR5: PathPlan
    t5 = uitab(tg,'Title','OR5:PathPlan','BackgroundColor',C.BP);
    btn(t5,[0.03 0.90 0.46 0.08],'Find Path',FN,C.BA,[1 1 1],@(~,~)onPathBtn(fig));
    btn(t5,[0.51 0.90 0.46 0.08],'Clear Path',FN,[.6 .3 .3],[1 1 1],@(~,~)onPathClear(fig));
    pathInfo = uicontrol('Parent',t5,'Style','text','Units','normalized','Position',[0.03 0.75 0.94 0.12],...
        'String','Click two points.','BackgroundColor',C.BP,'ForegroundColor',C.FL);

    stBar = uicontrol('Parent',fig,'Style','text','Units','normalized','Position',[0.005 0.005 0.99 0.045],...
        'BackgroundColor',[.14 .16 .21],'ForegroundColor',C.FO,'FontSize',10,'HorizontalAlignment','left','String','  Ready.');

% =====================================================================
%  5.  STATE & PERSISTENCE
% =====================================================================
    s = struct();
    s.Colors = C; s.MapImage = mapImage; s.MapHeight = mapH; s.MapWidth = mapW; s.Scale = 1.7; s.RoadMask = roadMask;
    s.RotationAngle = 0; s.RotatedImage = mapImage; s.OrigCenter = [(mapW+1)/2 (mapH+1)/2]; s.RotCenter = s.OrigCenter;
    s.InteractiveMode = 'idle'; s.IVList = []; s.NextIVID = 1; s.MeasPoints = []; s.MeasType = 'none';
    s.SkelPixPts = []; s.SkelWorldPts = []; s.PathPixels = [];
    
    s.Figure = fig; s.MapAxes = mapAx; s.StatusBar = stBar; s.ModeLabel = modeL; s.CoordLabel = coordDisplay;
    s.AngleInput = angIn; s.ScaleInput = scIn; s.IVListbox = ivLB; s.DistResult = dR; s.TrajResult = tR; s.RotAngleInput = rotIn;
    s.RangeInput = rgIn; s.LocalAxes = locAx; s.SVAxes = svAx; s.PathInfo = pathInfo; s.SkelAxes = skelAx; s.SkelInfo = skelInfo;
    s.ClickCB = @(~,~) onMapClick(fig);
    setappdata(fig,'AppState',s); set(hImg,'ButtonDownFcn',s.ClickCB); app = s;
end

% #####################################################################
%  CALLBACKS & LOGIC
% #####################################################################

function onMapClick(fig)
    s = getappdata(fig,'AppState'); cp = get(s.MapAxes,'CurrentPoint'); cC = cp(1,1); cR = cp(1,2);
    [dH,dW,~] = size(s.RotatedImage);
    if cC<0.5||cC>dW+0.5||cR<0.5||cR>dH+0.5, return; end
    if abs(s.RotationAngle)>0.001, [oR,oC] = r2o(cR,cC,s); else, oR=cR; oC=cC; end
    [wx,wy] = pixel_to_world(round(oR),round(oC),s.MapHeight,s.Scale);
    set(s.CoordLabel, 'String', sprintf('X: %.1f m, Y: %.1f m', wx, wy));

    switch s.InteractiveMode
    case 'idle'
        setSt(fig,sprintf('  Position: X=%.1f m, Y=%.1f m',wx,wy),s.Colors.FO);
    case 'add_iv'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            a=str2double(get(s.AngleInput,'String')); if isnan(a),a=0;end
            sf=str2double(get(s.ScaleInput,'String')); if isnan(sf)||sf<=0,sf=1.5;end
            niv=create_iv(s.NextIVID,wx,wy,a,sf); s.IVList = [s.IVList, niv]; s.NextIVID=s.NextIVID+1;
            setSt(fig, sprintf('  SUCCESS: IV #%d added. Continuous mode active.', niv.ID-1), s.Colors.FO);
            setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig);
        else, setSt(fig,'  ERROR: Not on road!',s.Colors.ERR); end
    case 'measure_dist'
        s.MeasType = 'dist'; s.MeasPoints = [s.MeasPoints; oR, oC, wx, wy];
        if size(s.MeasPoints, 1) == 2, s.InteractiveMode = 'idle'; set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',s.Colors.FO); end
        setappdata(fig,'AppState',s); refreshDisp(fig);
    case 'measure_traj'
        s.MeasType = 'traj'; s.MeasPoints = [s.MeasPoints; oR, oC, wx, wy];
        tLen = 0; for k=2:size(s.MeasPoints,1), tLen=tLen+sqrt((s.MeasPoints(k,3)-s.MeasPoints(k-1,3))^2+(s.MeasPoints(k,4)-s.MeasPoints(k-1,4))^2); end
        set(s.TrajResult,'String',sprintf('Traj: %.2f m',tLen)); setappdata(fig,'AppState',s); refreshDisp(fig);
    case 'skeleton'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            s.SkelWorldPts=[s.SkelWorldPts; wx wy]; s.SkelPixPts=[s.SkelPixPts; round(oR) round(oC)];
            set(s.SkelInfo, 'String', sprintf('Points: %d', size(s.SkelWorldPts,1)));
            setappdata(fig,'AppState',s); refreshDisp(fig); updateSkelAx(fig);
        end
    case 'auto_align'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            ang = find_road_direction(round(oR),round(oC),s.RoadMask);
            sf=str2double(get(s.ScaleInput,'String')); if isnan(sf),sf=1.5;end
            niv=create_iv(s.NextIVID,wx,wy,ang,sf); s.IVList = [s.IVList, niv]; s.NextIVID=s.NextIVID+1;
            setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig);
        end
    case 'street_view'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            ang = find_road_direction(round(oR),round(oC),s.RoadMask);
            svImg = generate_street_view(s.MapImage, round(oR), round(oC), ang, s.MapHeight, s.Scale);
            cla(s.SVAxes); imshow(svImg,'Parent',s.SVAxes); axis(s.SVAxes,'off');
        end
    case 'path_plan'
        s.MeasPoints = [s.MeasPoints; oR, oC, wx, wy];
        if size(s.MeasPoints, 1) == 2
            setSt(fig, '  Computing BFS Path...', s.Colors.FL); drawnow;
            [rr1,rc1] = find_nearest_road(round(s.MeasPoints(1,1)), round(s.MeasPoints(1,2)), s.RoadMask);
            [rr2,rc2] = find_nearest_road(round(s.MeasPoints(2,1)), round(s.MeasPoints(2,2)), s.RoadMask);
            [pR,pC] = road_path_bfs(s.RoadMask, rr1, rc1, rr2, rc2);
            if ~isempty(pR), s.PathPixels = [pR pC]; set(s.PathInfo,'String','Path Found!');
            else, set(s.PathInfo,'String','No path found.'); end
            s.InteractiveMode = 'idle'; s.MeasPoints = []; setappdata(fig,'AppState',s); refreshDisp(fig);
        end
    end
    setappdata(fig,'AppState',s);
end

function refreshDisp(fig)
    s=getappdata(fig,'AppState'); cla(s.MapAxes);
    hI=imshow(s.RotatedImage,'Parent',s.MapAxes); set(hI,'ButtonDownFcn',s.ClickCB);
    hold(s.MapAxes,'on');
    isRestricted = ~strcmp(s.InteractiveMode, 'idle') && ~strcmp(s.InteractiveMode, 'add_iv');
    for k=1:length(s.IVList)
        h = draw_iv(s.MapAxes,s.IVList(k),s.MapHeight,s.Scale,s.RotationAngle,s.OrigCenter,s.RotCenter);
        if isRestricted, for hh = h', set(hh, 'PickableParts', 'all', 'ButtonDownFcn', @(~,~) onMapClick(fig)); end
        else, set(h(1), 'HitTest', 'on', 'ButtonDownFcn', @(~,~) onIVSelected(fig, s.IVList(k).ID)); end
    end
    % REDRAW PERSISTENT GRAPHICS
    if ~isempty(s.MeasPoints)
        nP = size(s.MeasPoints,1); rPts = zeros(nP,2);
        for k=1:nP, [rPts(k,1),rPts(k,2)]=o2r(s.MeasPoints(k,1),s.MeasPoints(k,2),s); end
        if strcmp(s.MeasType,'dist')
            plot(s.MapAxes,rPts(:,2),rPts(:,1),'ro-','LineWidth',2,'MarkerSize',8);
            if nP==2, text(s.MapAxes,mean(rPts(:,2)),mean(rPts(:,1)),sprintf('%.1f m',sqrt((s.MeasPoints(2,3)-s.MeasPoints(1,3))^2+(s.MeasPoints(2,4)-s.MeasPoints(1,4))^2)),'Color','w','BackgroundColor',[.8 .2 .2],'HorizontalAlignment','center'); end
        elseif strcmp(s.MeasType,'traj'), plot(s.MapAxes,rPts(:,2),rPts(:,1),'y.-','LineWidth',1.5,'MarkerSize',14); end
    end
    if ~isempty(s.SkelPixPts)
        nP = size(s.SkelPixPts,1); rPts = zeros(nP,2);
        for k=1:nP, [rPts(k,1),rPts(k,2)]=o2r(s.SkelPixPts(k,1),s.SkelPixPts(k,2),s); end
        plot(s.MapAxes,rPts(:,2),rPts(:,1),'g-x','LineWidth',2);
    end
    if ~isempty(s.PathPixels)
        ps=s.PathPixels; pc=ps(:,2); pr=ps(:,1);
        if abs(s.RotationAngle)>0.001, for j=1:length(pc),[pr(j),pc(j)]=o2r(ps(j,1),ps(j,2),s);end; end
        plot(s.MapAxes,pc,pr,'m-','LineWidth',3);
    end
    hold(s.MapAxes,'off'); setappdata(fig,'AppState',s); updateLocalView(fig); updateSkelAx(fig);
end

% --- OR Support ---
function updateSkelAx(fig), s=getappdata(fig,'AppState'); if isempty(s.SkelWorldPts), return; end; cla(s.SkelAxes); plot(s.SkelAxes, s.SkelWorldPts(:,1), s.SkelWorldPts(:,2), 'g-o', 'LineWidth', 2); axis(s.SkelAxes,'equal'); grid(s.SkelAxes,'on'); end
function updateLocalView(fig), s=getappdata(fig,'AppState'); sel=get(s.IVListbox,'Value'); if isempty(s.IVList)||sel>length(s.IVList), cla(s.LocalAxes); return; end; iv=s.IVList(sel); rM=str2double(get(s.RangeInput,'String')); if isnan(rM),rM=100;end; [cR,cC]=world_to_pixel(iv.WorldX,iv.WorldY,s.MapHeight,s.Scale); li=local_map_view(s.MapImage,cR,cC,rM/s.Scale); cla(s.LocalAxes); imshow(li,'Parent',s.LocalAxes); hold(s.LocalAxes,'on'); R=size(li,1)/2; cosA=cos(iv.Angle*pi/180); sinA=sin(iv.Angle*pi/180); L=(iv.Length*iv.ScaleFactor)/s.Scale*1.5; W=(iv.Width*iv.ScaleFactor)/s.Scale*1.5; px=[-L/2,L/2*0.6,L/2*1.4,L/2*0.6,-L/2]; py=[-W/2,-W/2,0,W/2,W/2]; patch(cosA*px-sinA*py+R,sinA*px+cosA*py+R,[1 1 0.4],'Parent',s.LocalAxes,'EdgeColor','w'); end

% --- Core Functions ---
function onRotate(fig), s=getappdata(fig,'AppState'); add_a=str2double(get(s.RotAngleInput,'String')); if isnan(add_a),return;end; s.RotationAngle=s.RotationAngle+add_a; [ri,nh,nw]=rotate_map(s.MapImage,s.RotationAngle); s.RotatedImage=ri; s.RotCenter=[(nw+1)/2 (nh+1)/2]; setappdata(fig,'AppState',s); refreshDisp(fig); end
function onResetView(fig), s=getappdata(fig,'AppState'); s.RotationAngle=0; s.RotatedImage=s.MapImage; s.RotCenter=s.OrigCenter; set(s.RotAngleInput,'String','90'); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onAddIV(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='add_iv'; set(s.ModeLabel,'String','Mode: ADD IV (Continuous)'); setappdata(fig,'AppState',s); end
function onRemoveIV(fig), s=getappdata(fig,'AppState'); sel=get(s.IVListbox,'Value'); if isempty(s.IVList),return;end; s.IVList(sel)=[]; set(s.IVListbox,'Value',max(1,sel-1)); setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig); end
function onReportIV(fig), s=getappdata(fig,'AppState'); if isempty(s.IVList),return;end; msg=cell(length(s.IVList),1); for k=1:length(s.IVList),iv=s.IVList(k);msg{k}=sprintf('IV#%d: X=%.1fm, Y=%.1fm',iv.ID,iv.WorldX,iv.WorldY);end; msgbox(msg,'Report'); end
function onDistBtn(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='measure_dist'; s.MeasPoints=[]; s.MeasType='dist'; set(s.ModeLabel,'String','Mode: DISTANCE'); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onTrajBtn(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='measure_traj'; s.MeasPoints=[]; s.MeasType='traj'; set(s.ModeLabel,'String','Mode: TRAJECTORY'); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onClearMeas(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='idle'; s.MeasPoints=[]; s.MeasType='none'; s.PathPixels=[]; s.SkelPixPts=[]; s.SkelWorldPts=[]; set(s.ModeLabel,'String','Mode: Idle'); set(s.DistResult,'String','Dist: --'); set(s.TrajResult,'String','Traj: --'); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onSkelExtract(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='skeleton'; set(s.ModeLabel,'String','Mode: SKELETON'); setappdata(fig,'AppState',s); end
function onSkelEnd(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='idle'; set(s.ModeLabel,'String','Mode: Idle'); setappdata(fig,'AppState',s); end
function onSkelClear(fig), s=getappdata(fig,'AppState'); s.SkelPixPts=[]; s.SkelWorldPts=[]; cla(s.SkelAxes); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onSkelShow(fig), updateSkelAx(fig); end
function onSkelRoadArea(fig), s=getappdata(fig,'AppState'); if isempty(s.SkelPixPts),return;end; mi=s.MapImage; mask=build_road_mask(mi); cla(s.SkelAxes); imshow(mi.*uint8(mask),'Parent',s.SkelAxes); end
function onAutoAddIV(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='auto_align'; set(s.ModeLabel,'String','Mode: AUTO-ALIGN'); setappdata(fig,'AppState',s); end
function onHeadUp(fig), s=getappdata(fig,'AppState'); sel=get(s.IVListbox,'Value'); if isempty(s.IVList),return;end; iv=s.IVList(sel); a=90-iv.Angle; s.RotationAngle=a; [ri,nh,nw]=rotate_map(s.MapImage,a); s.RotatedImage=ri; s.RotCenter=[(nw+1)/2 (nh+1)/2]; setappdata(fig,'AppState',s); refreshDisp(fig); end
function onStreetViewBtn(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='street_view'; set(s.ModeLabel,'String','Mode: STREET VIEW'); setappdata(fig,'AppState',s); end
function onPathBtn(fig), s=getappdata(fig,'AppState'); s.InteractiveMode='path_plan'; s.MeasPoints=[]; set(s.ModeLabel,'String','Mode: PATH PLAN'); setappdata(fig,'AppState',s); refreshDisp(fig); end
function onPathClear(fig), s=getappdata(fig,'AppState'); s.PathPixels=[]; setappdata(fig,'AppState',s); refreshDisp(fig); end
function onIVSelected(fig,ivID), s=getappdata(fig,'AppState'); idx=find([s.IVList.ID]==ivID); if ~isempty(idx),set(s.IVListbox,'Value',idx);updateLocalView(fig);end; end
function updateIVLB(fig), s=getappdata(fig,'AppState'); if isempty(s.IVList),set(s.IVListbox,'String',{'(none)'});return;end; items=cell(1,length(s.IVList)); for k=1:length(s.IVList),items{k}=sprintf('IV#%d (%.0f,%.0f)',s.IVList(k).ID,s.IVList(k).WorldX,s.IVList(k).WorldY);end; set(s.IVListbox,'String',items); end
function [oR,oC] = r2o(rR,rC,s), a=s.RotationAngle*pi/180; ca=cos(a); sa=sin(a); dc=rC-s.RotCenter(1); dr=rR-s.RotCenter(2); oC=ca*dc-sa*dr+s.OrigCenter(1); oR=sa*dc+ca*dr+s.OrigCenter(2); end
function [rR,rC] = o2r(oR,oC,s), a=s.RotationAngle*pi/180; ca=cos(a); sa=sin(a); dc=oC-s.OrigCenter(1); dr=oR-s.OrigCenter(2); rC=ca*dc+sa*dr+s.RotCenter(1); rR=-sa*dc+ca*dr+s.RotCenter(2); end
function setSt(fig,msg,clr), s=getappdata(fig,'AppState'); set(s.StatusBar,'String',msg,'ForegroundColor',clr); end
function lab(p,pos,txt,fn,bg,fg), uicontrol('Parent',p,'Style','text','Units','normalized','Position',pos,'String',txt,'FontName',fn,'FontSize',9,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left'); end
function h=btn(p,pos,txt,fn,bg,fg,cb), h=uicontrol('Parent',p,'Style','pushbutton','Units','normalized','Position',pos,'String',txt,'FontName',fn,'FontSize',9,'FontWeight','bold','BackgroundColor',bg,'ForegroundColor',fg,'Callback',cb); end
function sep(p,y,clr), uicontrol('Parent',p,'Style','text','Units','normalized','Position',[0.03 y 0.94 0.002],'BackgroundColor',clr); end
function stit(p,y,txt,fn,bg,fg), uicontrol('Parent',p,'Style','text','Units','normalized','Position',[0.03 y 0.94 0.022],'String',txt,'FontName',fn,'FontSize',9,'FontWeight','bold','BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','center'); end