%% MOSAiC IMB: reproduce five figures from the processed NetCDF
% Run this saved script from any MATLAB working directory.
% MATLAB R2024a recommended; base MATLAB functions only.
% Existing five PNGs in figures/ are replaced; the NetCDF is read-only.
% Creator: Evgenii Salganik
% Affiliation: Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research (AWI)
% No MAT files, interface reconstruction, re-averaging, or repeat smoothing.
close all; clear; clc;
% Supported layouts: repo/scripts/this_script.m or repo/this_script.m.
% Expected input: repo/data/MOSAiC_IMB_extended_v1.nc
scriptDir=fileparts(mfilename('fullpath'));
assert(~isempty(scriptDir),'Save this script as an .m file before running it.');
if isfolder(fullfile(scriptDir,'data'))
    repoRoot=scriptDir;
else
    repoRoot=fileparts(scriptDir);
end
folder=fullfile(repoRoot,'data');
assert(isfolder(folder),'Repository data folder not found: %s',folder);
% Explicit version gives reproducible input selection; change here for a release.
ncFile=fullfile(folder,'MOSAiC_IMB_extended_v1.nc');
assert(isfile(ncFile),'NetCDF not found: %s',ncFile);
fprintf('Importing: %s\n',ncFile);
info=ncinfo(ncFile);
variables=string({info.Variables.Name});
required=["snow_depth_mean_raw","ice_thickness_mean_raw", ...
    "snow_depth_mean","snow_depth_std","ice_thickness_mean", ...
    "ice_thickness_std","ensemble_included", ...
    "snow_ensemble_included","ice_ensemble_included","snow_depth_N","ice_thickness_N"];
assert(all(ismember(required,variables)), ...
    'NetCDF lacks required smoothed-summary variables. Use the processed dataset distributed with this repository.');

%% Same plotting configuration as the processing script
cfg.plotPadding=0.12;
cfg.temperatureLimits=[-15 2];
cfg.simbaHeatingLimits=[0.3 1.5];
cfg.dtcHeatingLimits=[1 4];
cfg.summaryStart=NaT; % Default: full hourly NetCDF coverage
cfg.summaryFinish=NaT;
cfg.savePlots=true;
cfg.exportDir=fullfile(repoRoot,'figures');

%% Import hourly data and statistics exactly as stored
D.time=readNCTime(ncFile,'time');
if isnat(cfg.summaryStart), cfg.summaryStart=min(D.time); end
if isnat(cfg.summaryFinish), cfg.summaryFinish=max(D.time); end
D.labels=string(ncread(ncFile,'imb_lbl')); D.labels=D.labels(:);
n=numel(D.labels); nt=numel(D.time);
assert(n>0,'No buoy labels found.');
D.model=string(ncread(ncFile,'geometry_model'));
D.surface=reshape(double(ncread(ncFile,'z_surface')),n,nt);
D.iceTop=reshape(double(ncread(ncFile,'z_ice_top')),n,nt);
D.iceBottom=reshape(double(ncread(ncFile,'z_ice_bottom')),n,nt);
D.snowDepth=reshape(double(ncread(ncFile,'snow_thick')),n,nt);
D.iceThickness=reshape(double(ncread(ncFile,'ice_thick')),n,nt);
D.ensemble.included=logical(ncread(ncFile,'ensemble_included'));
D.ensemble.snowIncluded=logical(ncread(ncFile,'snow_ensemble_included'));
D.ensemble.iceIncluded=logical(ncread(ncFile,'ice_ensemble_included'));
D.ensemble.included=D.ensemble.included(:);
D.ensemble.snowIncluded=D.ensemble.snowIncluded(:);
D.ensemble.iceIncluded=D.ensemble.iceIncluded(:);
for kind=["snow","ice"]
    if kind=="snow", prefix='snow_depth'; else, prefix='ice_thickness'; end
    S.meanSmooth=double(ncread(ncFile,[prefix '_mean'])); S.meanSmooth=S.meanSmooth(:);
    S.stdSmooth=double(ncread(ncFile,[prefix '_std'])); S.stdSmooth=S.stdSmooth(:);
    S.meanRaw=double(ncread(ncFile,[prefix '_mean_raw'])); S.meanRaw=S.meanRaw(:);
    S.stdRaw=double(ncread(ncFile,[prefix '_std_raw'])); S.stdRaw=S.stdRaw(:);
    S.count=double(ncread(ncFile,[prefix '_N'])); S.count=S.count(:);
    D.ensemble.(kind)=S;
end
% Read the stored smoothing setting rather than applying smoothing again.
processing=char(ncreadatt(ncFile,'snow_depth_mean','processing'));
token=regexp(processing,'^(\d+)-hour','tokens','once');
assert(~isempty(token),'Cannot identify smoothing duration from NetCDF metadata.');
cfg.smoothingHours=str2double(token{1});
excluded=D.labels(~D.ensemble.included);
fprintf('Hourly data: %s to %s; %d samples\n',char(min(D.time)),char(max(D.time)),nt);
fprintf('Stored summary smoothing: %g days. Excluded: %s\n', ...
    cfg.smoothingHours/24,strjoin(excluded,', '));
fprintf('Snow summary exclusions: %s\n',strjoin(D.labels(~D.ensemble.snowIncluded),', '));
fprintf('Ice summary exclusions: %s\n',strjoin(D.labels(~D.ensemble.iceIncluded),', '));
% Verify that plotted active counts correspond to the data and saved selections.
assert(isequal(sum(isfinite(D.snowDepth(D.ensemble.snowIncluded,:)),1).', ...
    D.ensemble.snow.count),'Stored snow count does not match data/inclusion flags.');
assert(isequal(sum(isfinite(D.iceThickness(D.ensemble.iceIncluded,:)),1).', ...
    D.ensemble.ice.count),'Stored ice count does not match data/inclusion flags.');

%% Native temperature/heating and FINAL interfaces used in original plots
nativeBuoys=repmat(struct('label',"",'time',NaT(0,1), ...
    'heatingTime',NaT(0,1),'sensorZ',[], ...
    'temperature',[],'heating',[],'surface',[], ...
    'iceTop',[],'iceBottom',[],'snowDepth',[],'iceThickness',[]),n,1);
for k=1:n
    group=['/buoys/' char(D.labels(k)) '/'];
    nativeBuoys(k).label=D.labels(k);
    nativeBuoys(k).time=readNCTime(ncFile,[group 'time_temperature']);
    nativeBuoys(k).heatingTime=readNCTime(ncFile,[group 'time_heating']);
    z=double(ncread(ncFile,[group 'sensor_z']));
    nativeBuoys(k).sensorZ=z(:).';
    nz=numel(z);
    nT=numel(nativeBuoys(k).time);
    nH=numel(nativeBuoys(k).heatingTime);
    nativeBuoys(k).temperature=reshape( ...
        double(ncread(ncFile,[group 'temperature'])),nT,nz);
    nativeBuoys(k).heating=reshape( ...
        double(ncread(ncFile,[group 'heating'])),nH,nz);
    for name=["surface","iceTop","iceBottom","snowDepth","iceThickness"]
        values=double(ncread(ncFile,[group char(name)]));
        nativeBuoys(k).(char(name))=values(:);
    end
end

%% Same plotting functions as processing script
for region=1:2
    for field=1:2
        allBuoyPanels(nativeBuoys,cfg,region,field);
    end
end
cleanMeanComparison(D,cfg);

%% Save recreated figures separately; existing processing plots are preserved
if cfg.savePlots
    if ~isfolder(cfg.exportDir), mkdir(cfg.exportDir); end
    figs=findall(groot,'Type','figure');
    for j=1:numel(figs)
        switch string(figs(j).Name)
            case "Surface interfaces | Temperature | all buoys"
                name='surface_temperature.png';
            case "Surface interfaces | Heating | all buoys"
                name='surface_heating.png';
            case "Ice-bottom interface | Temperature | all buoys"
                name='bottom_temperature.png';
            case "Ice-bottom interface | Heating | all buoys"
                name='bottom_heating.png';
            case "MOSAiC_mean_snow_ice_thickness"
                name='mean_snow_ice_thickness.png';
            otherwise
                error('Unexpected figure name: %s',figs(j).Name);
        end
        output=fullfile(cfg.exportDir,name);
        exportgraphics(figs(j),output,'Resolution',300);
        fprintf('Saved: %s\n',output);
    end
end
fprintf('Done: all figure data read directly from NetCDF; no repeat smoothing.\n');

%% Local plotting functions copied from the processing script
function drawn=fastField(a,time,z,data,startTime,endTime,zLimits)
    % One flat-colour surface, not hundreds of contour polygons.
    % Retains actual timestamps and sensor elevations (including irregular grids).
    % Crops the field BEFORE rendering. No smoothing or griddata interpolation.
    drawn=false;
    x=datenum(time(:)); z=z(:);
    assert(isequal(size(data),[numel(x),numel(z)]), ...
        'Profile matrix must be time x sensor.');
    [x,ix]=sort(x); [z,iz]=sort(z);
    C=data(ix,iz).';
    [x,ix]=unique(x,'stable'); C=C(:,ix);
    [z,iz]=unique(z,'stable'); C=C(iz,:);
    it=find(x>=datenum(startTime) & x<=datenum(endTime));
    iz=find(z>=zLimits(1) & z<=zLimits(2));
    if isempty(it) || isempty(iz), return; end
    % One neighbouring sample on each side covers the requested limits.
    it=max(1,it(1)-1):min(numel(x),it(end)+1);
    iz=max(1,iz(1)-1):min(numel(z),iz(end)+1);
    x=x(it); z=z(iz); C=C(iz,it);
    if numel(x)<2 || numel(z)<2 || ~any(isfinite(C(:))), return; end
    % Do not visually bridge long absent measurement periods.
    step=median(diff(x)); gaps=find(diff(x)>3*step);
    for j=numel(gaps):-1:1
        k=gaps(j); mid=(x(k)+x(k+1))/2;
        x=[x(1:k);mid;x(k+1:end)];
        C=[C(:,1:k),nan(size(C,1),1),C(:,k+1:end)];
    end
    [X,Y]=meshgrid(x,z);
    surface(a,X,Y,zeros(size(C)),C,'FaceColor','flat', ...
        'EdgeColor','none','HandleVisibility','off');
    drawn=true;
end


function allBuoyPanels(native,cfg,region,field)
    if region==1, area="Surface interfaces"; else, area="Ice-bottom interface"; end
    if field==1, variable="Temperature"; else, variable="Heating"; end
    fig=figure('Color','w','WindowState','maximized', ...
        'Name',char(area+" | "+variable+" | all buoys"));
    tl=tiledlayout(fig,ceil(numel(native)/3),3,'TileSpacing','compact','Padding','compact');
    title(tl,area+" | "+variable+" | final processing geometry");
    allAxes=gobjects(numel(native),1);
    for k=1:numel(native)
        g=native(k); a=nexttile(tl); allAxes(k)=a; hold(a,'on');
        win=g.time>=cfg.summaryStart & g.time<=cfg.summaryFinish;
        if region==1, values=[g.surface(win);g.iceTop(win)];
        else, values=g.iceBottom(win); end
        values=values(isfinite(values));
        if isempty(values)
            title(a,g.label); text(a,0.1,0.5,'No interfaces in window','Units','normalized');
            continue
        end
        lim=[min(values)-cfg.plotPadding,max(values)+cfg.plotPadding];
        if field==1
            fastField(a,g.time,g.sensorZ,g.temperature,cfg.summaryStart,cfg.summaryFinish,lim);
            clim(a,cfg.temperatureLimits);
        else
            fastField(a,g.heatingTime,g.sensorZ,g.heating,cfg.summaryStart,cfg.summaryFinish,lim);
            if startsWith(g.label,"DTC"), clim(a,cfg.dtcHeatingLimits);
            else, clim(a,cfg.simbaHeatingLimits); end
            if ~any(isfinite(g.heating(:)))
                text(a,0.05,0.7,'No heating supplied','Units','normalized');
            end
        end
        if region==1
            h1=plot(a,datenum(g.time),g.surface,'k-','LineWidth',1.3);
            h2=plot(a,datenum(g.time),g.iceTop,'m--','LineWidth',1.3);
            if k==1
                legend(a,[h1 h2],{'Top surface','Ice top / snow bottom'}, ...
                    'Location','best','FontSize',7,'AutoUpdate','off');
            end
        else
            plot(a,datenum(g.time),g.iceBottom,'k-','LineWidth',1.3);
        end
        title(a,g.label,'FontSize',10);
        ylim(a,lim); xlim(a,datenum([cfg.summaryStart cfg.summaryFinish]));
        datetick(a,'x','mmm dd','keeplimits');
        set(a,'YDir','normal','FontSize',8,'Layer','top');
        ylabel(a,'z (m)'); box(a,'on'); colormap(a,turbo);
        % Heating protocols have different scales: colorbars show each panel's limits.
        drawnow;
        c=colorbar(a); c.FontSize=7;
    end
    if field==1
        subtitle(tl,'Colour: temperature (deg C); elevations in each buoy source datum');
    else
        subtitle(tl,'Colour: heating response (deg C); DTC 1-4, SIMBA/IMB 0.3-1.5');
    end
end


function cleanMeanComparison(D,cfg)
    % Only one mean curve and +/- one ensemble SD per panel.
    E=D.ensemble;
    fig=figure('Color','w','Name','MOSAiC_mean_snow_ice_thickness', ...
        'Units','inches','Position',[1 1 9 8]);
    tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
    colors=lines(2); aa=gobjects(3,1);
    for panel=1:2
        a=nexttile(tl); aa(panel)=a; hold(a,'on');
        if panel==1
            S=E.snow; ytext='Snow thickness (m)';
        else
            S=E.ice; ytext='Ice thickness (m)';
        end
        mu=S.meanSmooth; sd=S.stdSmooth;
        valid=isfinite(mu)&isfinite(sd);
        edges=diff([false;valid;false]);
        starts=find(edges==1); ends=find(edges==-1)-1;
        for r=1:numel(starts)
            ix=starts(r):ends(r);
            if numel(ix)<2, continue; end
            fill(a,[D.time(ix);flipud(D.time(ix))], ...
                [mu(ix)-sd(ix);flipud(mu(ix)+sd(ix))],colors(panel,:), ...
                'FaceAlpha',0.14,'EdgeColor','none','HandleVisibility','off');
        end
        plot(a,D.time,mu,'Color',colors(panel,:),'LineWidth',1.8);
        ylabel(a,ytext);
        if panel==2, set(a,'YDir','reverse'); end
        xlim(a,[min(D.time),max(D.time)]); xtickformat(a,'MMM yyyy');
        set(a,'FontSize',10,'LineWidth',0.8,'GridAlpha',0.12);
        grid(a,'on'); box(a,'on');
        text(a,0.015,0.96,sprintf('(%c)',char('a'+panel-1)), ...
            'Units','normalized','VerticalAlignment','top');
    end
    title(tl,sprintf('Extended buoy mean +/- 1 SD | %g-day smoothing',cfg.smoothingHours/24));
    % Counts are the stored UNSMOOTHED number of contributors to each mean.
    % Snow and ice have separate inclusion flags and finite-data availability.
    a=nexttile(tl); aa(3)=a;
    stairs(a,D.time,E.snow.count,'Color',colors(1,:),'LineWidth',1.3);
    hold(a,'on');
    stairs(a,D.time,E.ice.count,'--','Color',colors(2,:),'LineWidth',1.3);
    ylabel(a,'Contributing buoys'); xlabel(a,'Date');
    legend(a,{'Snow','Ice'},'Location','best','Box','off');
    xlim(a,[min(D.time),max(D.time)]);
    maximum=max([E.snow.count(:);E.ice.count(:)]);
    ylim(a,[0,max(2,maximum+1)]);
    yticks(a,0:5:max(5,5*ceil((maximum+1)/5)));
    grid(a,'on'); box(a,'on'); xtickformat(a,'MMM yyyy');
    set(a,'FontSize',10,'LineWidth',0.8,'GridAlpha',0.12);
    text(a,0.015,0.96,'(c)','Units','normalized','VerticalAlignment','top');
    aa(1).XTickLabel=[]; aa(2).XTickLabel=[]; linkaxes(aa,'x');
end


function t=readNCTime(file,name)
    units=char(ncreadatt(file,name,'units'));
    token=regexp(strtrim(units),'^(days?|hours?|seconds?)\s+since\s+(.+)$','tokens','once');
    assert(~isempty(token),'Unsupported time units: %s',units);
    txt=strrep(strtrim(token{2}),'T',' ');
    txt=strtrim(regexprep(txt,'\s*(UTC|Z)$',''));
    if numel(txt)==10
        origin=datetime(txt,'InputFormat','yyyy-MM-dd');
    else
        try, origin=datetime(txt,'InputFormat','yyyy-MM-dd HH:mm:ss');
        catch, origin=datetime(txt,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS'); end
    end
    x=double(ncread(file,name));
    if startsWith(token{1},'day'), offset=days(x);
    elseif startsWith(token{1},'hour'), offset=hours(x);
    else, offset=seconds(x); end
    t=origin+offset(:);
end
