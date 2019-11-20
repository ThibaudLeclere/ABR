function ABR_GUI(abrObj)
close all

fig = figure;
importButton = uicontrol(fig, 'Style', 'pushbutton'...
                             , 'String', 'Import File'...
                             , 'FontUnits', 'Normalized'...
                             , 'FontSize', .5 ...
                             , 'Callback', @importFile ...
                             , 'Units', 'Normalized'...
                             , 'Position', [0.02 0.9 0.1 0.05]...
                          );

uicontrol(fig, 'Style', 'text'...
             , 'String', 'Imported File: None'...
             , 'FontUnits', 'Normalized' ...
             , 'FontSize', 0.5 ...
             , 'HorizontalAlignment', 'Left'...
             , 'Tag', 'importedFileLabel'...
             , 'Units', 'Normalized'...
             , 'Position', importButton.Position - [-0.12 0 -0.2 0]...
             );
                            
uicontrol(fig, 'Style', 'pushbutton'...
             , 'String', 'Save All Figures'...
             , 'FontUnits', 'Normalized'...
             , 'FontSize', .5 ...
             , 'Callback', @save_allFigures ...
             , 'Units', 'Normalized'...
             , 'Position', [0.72 0.9 0.1 0.05]...
             );
            
         
if nargin == 1 
    if ischar(abrObj)
       abrObj = ABR.openFile(abrObj); 
    end
    
    % Store data
    [data, Nabrs] = initialize(abrObj);
    
    guidata(fig, data)
    generateTabs(fig, Nabrs);
    
end
end


function [data, Nabrs] = initialize(abrObj)
    Nabrs = numel(abrObj);
    % Initialize data structure
    data(1:Nabrs, 1) = struct('abr', []...
                        , 'waves', []...
                        , 'latencies', []...   
                        , 'peakDetectionSettings', []...
                         );  
     
   % Save abr objects in data structure                  
   for i = 1:Nabrs
        data(i).abr = abrObj(i);
%         data(i).noiseLevel = estimate_Noise(abrObj(i).amplitude, abrObj(i).fs);
   end
    % Delete potential previous plots
    tbGroup = findobj('Tag', 'tabGroup');
    delete(tbGroup)
end

function importFile(buttonObj, ~)
                       
    [file, path] = uigetfile('*.txt');
    if file == 0 % If users clicked "cancel" or closed the window
        return
    end
    
    filename = fullfile(path, file);
    
   abr = ABR.openFile(filename); 
   
   [data, Nabrs] = initialize(abr);
   
   importedFileLabel = findobj('Tag', 'importedFileLabel');
   importedFileLabel.String = file;
   
   
   
   guidata(buttonObj, data)
   generateTabs(buttonObj.Parent, Nabrs)
    
end


function generateTabs(parent, N)
    tabgp = uitabgroup(parent, 'Position', [0.02 0.02 .9 .85]...
                             , 'Tag', 'tabGroup'...
                             , 'TabLocation', 'left'...
                             );
    
    data = guidata(parent);
    for n = 1:N
        tab = uitab(tabgp, 'Title', data(n).abr.label...
                         , 'Tag', num2str(n)...
                         );
                     
    
        ax = axes(tab, 'Position', [0.08 0.1 0.6 0.7]...
                     , 'Box', 'on'...
                     , 'FontSize', 14 ...
                     , 'Tag',sprintf('Ax%d', n)...
                     , 'Ygrid', 'on'...
                     , 'ButtonDownFcn', @click_Ax ...
                     );
        hold on
        
        % Save Figure button
        uicontrol(tab, 'Style', 'pushbutton'...
                     , 'String', 'Save Figure'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized' ...
                     , 'FontSize', 0.5 ...
                     , 'Position', [ax.Position(1)+ax.Position(3)-0.1 0.9 0.1 0.05]...
                     , 'Callback', {@save_Figure, ax, n} ...
                     );
                 
        % Save points button         
        uicontrol(tab, 'Style', 'pushbutton'...
                     , 'String', 'Save Points'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.5 ...
                     , 'Position', [ax.Position(1)+ax.Position(3)-0.1 0.85 0.1 0.05]...
                     , 'Callback', {@save_Points , n}...
                    );
        
        
        % Export button      
        uicontrol(tab, 'Style', 'pushbutton'...
                     , 'String', 'Export'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.5 ...
                     , 'Position', [0.73 0.04 0.1 0.05]...
                     , 'Callback', {@export , n}...
                    );    
                
        uitable(tab, 'ColumnName', {'Timepoints', 'Amplitudes'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.73 0.1 0.25 0.2]...
                   , 'Tag', sprintf('wavePoints%d', n)...
                   );   
               
        uitable(tab, 'ColumnName', {'Peak to peak amplitudes', 'Latencies'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.73 0.35 0.25 0.2]...
                   , 'Tag', sprintf('amplitudes%d', n)...
                   );
         
        % Change timeunit
        uicontrol(tab, 'Style', 'text'...
                     , 'String', 'Time Units'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.25 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0 0.9 0.1 0.1]...
                     )
                 
        uicontrol(tab, 'Style', 'popupmenu'...
                     , 'String', {'µs', 'ms', 's'}...
                     , 'Value', 3 ...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.25 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0.12 0.9 0.04 0.1]...
                     , 'Tag', 'timeunitMenu'...
                     , 'Callback', {@update_unit, n, 'timeunit'} ...
                     );
                 
        % Change amplitude unit  
        uicontrol(tab, 'Style', 'text'...
                     , 'String', 'Amplitude Units'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.25 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0 0.85 0.1 0.1]...
                     );
                 
        uicontrol(tab, 'Style', 'popupmenu'...
                     , 'String', {'µV', 'mV', 'V'}...
                     , 'Value', 3 ...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.25 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0.12 0.85 0.04 0.1]...
                     , 'Tag', 'ampunitMenu'...
                     , 'Callback', {@update_unit, n, 'ampunit'} ...
                     );
        
                 
         % Show/hide noise estimation
         uicontrol(tab, 'Style', 'Checkbox'...
                      , 'String', 'Show Noise Estimation'...
                      , 'Value', 1 ...
                      , 'FontUnits', 'Normalized'...
                      , 'FontSize', 0.4 ...
                      , 'Units', 'Normalized'...
                      , 'Position', [0.017,0.85,0.15,0.05]...
                      , 'Tag', 'noiseCheckBox'...
                      , 'Callback', {@showNoise, n}...
                      );
                  
        % Noise level estimation
%         uicontrol(tab, 'Style', 'Text'...
%                      , 'String', sprintf('Noise Confidence Interval (V): [%f %f]', data(n).abr.noiseLevel(1), data(n).abr.noiseLevel(2))...
%                      , 'FontUnits', 'Normalized'...
%                      , 'FontSize', 0.5 ...
%                      , 'Units', 'Normalized'...
%                      , 'Position', [0.184829833454017,0.93,0.359956553222301,0.048139240506329]...
%                      );


        % Peak Detection  Panel
        peakPanel = uipanel(tab, 'Position', [0.73,0.55,0.25,0.45]);
        
        % Sliders
        peakDetectionSettings = ["Npeaks", "Height", "Prominence", "Threshold", "Distance", "Width"];
        ranges = [1, 0, 0, 0, 0, 0; 
                  8, 5, 5, 5, 5, 5];
        steps = repmat(1./(ranges(2,:)-ranges(1,:)), 2,1);
        
        yoffset = 0.1;
        for k = 1:length(peakDetectionSettings)
            label = uicontrol(peakPanel, 'Style', 'Text'...
                                        , 'String', sprintf('%s: 0', peakDetectionSettings(k)) ...
                                        , 'HorizontalAlignment', 'Left' ...
                                        , 'FontUnits', 'Normalized'...
                                        , 'FontSize', 0.8 ...
                                        , 'Units', 'Normalized'...
                                        , 'Position', [0.01,0.90-(k-1)*yoffset,0.45,0.09]...
                                        );

            uicontrol(peakPanel, 'Style', 'slider'...
                                , 'Min', ranges(1,k) ...
                                , 'Max', ranges(2,k) ...
                                , 'SliderStep', [steps(1,k) steps(2,k)]...
                                , 'Value', 4 ...
                                , 'Units', 'Normalized'...
                                , 'Position', [0.5,0.90-(k-1)*yoffset,0.45,0.05] ...
                                , 'Callback', {@set_DetectionSetting, label, n} ...
                                , 'Tag', sprintf('slider_%s', peakDetectionSettings(k)) ...
                                );
        end
                       
        % Automatic peak detection
        uicontrol(peakPanel, 'Style', 'pushbutton'...
                     , 'String', 'Detect Peaks'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.4 ...
                     , 'Position', [0.46,0.015,0.54,0.2]...
                     , 'Callback', {@detect_Peaks, ax, n} ...
                     );
                 
        data(n).dataCursorObj = datacursormode(parent);       
        data(n).abr.plot(ax)  
        
%         plot_ABR(tabgp, n)
    end
    guidata(parent, data)
end



% --------------- CALLBACKS ---------------------

function showNoise(checkbox, ~, n)
%     data = guidata(checkbox);
    
    if checkbox.Value
        show = 'on';
    else
        show = 'off';
    end
    currentAx = findobj('Tag', sprintf('Ax%d', n));
    lines = findobj(currentAx, 'Tag', 'noiseLevel');
    txt = findobj(currentAx, 'Tag', 'noiseLevel_Label');
    
    [lines.Visible] = deal(show);
    [txt.Visible] = deal(show);  
    
end

% ------------- PEAK DETECTION -----------------
function detect_Peaks(button, ~, ax, n)
    data = guidata(button);
    abrSig = data(n).abr.amplitude;
    fs = data(n).abr.fs;
    t = data(n).abr.timeVector;
    noiseLevel = data(n).abr.noiseLevel;
%     t = data(n).abr.timeVector;
%     t = Scale.convert_Units(t, data(n).abr.timeScale, Scale('m')); % convert in ms
    
    % Get positive peaks
    [peaks, locs, w, p] = findpeaks(abrSig(t>1e-3), t(t>1e-3), 'MinPeakHeight', noiseLevel(1)...
                                        ..., 'MinPeakProminence', 0.5 ...
                                        , 'NPeaks', data(n).peakDetectionSettings.Npeaks ...
                                        , 'Annotate', 'extents'...
                                        );
                                    
    
    
    % Get negative peaks
%     [negPeaks, negLocs] = findpeaks(-abrSig, fs, 'MinPeakHeight', -noiseLevel(2)...
%                                                ..., 'MinPeakProminence', 0.5 ...
%                                                , 'NPeaks', 4 ...
%                                                );
                                           
    % Remove peaks in the noise region
%     peaks = peaks(locs>1e-3);
%     w = w(locs>1e-3);
%     p = p(locs>1e-3);
%     locs = locs(locs>1e-3);
%     negPeaks = negPeaks(negLocs>1e-3);
%     negLocs = negLocs(negLocs>1e-3);
    
    
    % Plot on the graph
%     plot(ax, locs, peaks, 'o')
%     plot(ax, negLocs, -negPeaks, 'o') 
    abrPlot = findobj('Tag', sprintf('recording_%d', data(n).abr.level));
    for i = 1:length(peaks)
        line(ax,[locs(i) locs(i)], [peaks(i) peaks(i)-p(i)], 'Color', 'g', 'Tag', sprintf('Peak%d', i))
        line(ax, [locs(i)-w(i)/2 locs(i)+w(i)/2], [peaks(i)-p(i)/2 peaks(i)-p(i)/2], 'Color', 'b', 'Tag', sprintf('Width%d', i))
%         dt = datatip(abrPlot, locs(i), peaks(i));
    end
%     for j = 1:length(negPeaks)
%         dt = datatip(abrPlot, negLocs(j), -negPeaks(j));
%     end
    
    guidata(button, data)
end
function set_DetectionSetting(sliderObj, ~, labelObj, n)
   
    data = guidata(sliderObj);    
    
    feature = extractAfter(sliderObj.Tag, '_');
    
    % Set prominence value in the data structure 
    data(n).peakDetectionSettings.(feature) = sliderObj.Value;
    
    % Update slider label
    update_Label(labelObj, sliderObj.Value)
%     label = findobj('Tag', sprintf('prominenceSliderLabel%d', n));
%     label.String = num2str(sliderObj.Value);
    
    guidata(sliderObj, data)
    
    ax = findobj('Tag', sprintf('Ax%d', n));
    clean_Peaks(ax)
    detect_Peaks(sliderObj, [], ax, n)
end

function update_Label(labelObj, val)
    setting = extractBefore(labelObj.String, ':');
    setting = replace(setting, ' ', '');
    labelObj.String = join([setting, ":", num2str(val)]);
    
end

function clean_Peaks(ax)
    disp('Clean peaks')
    
    % Clean graphic lines
    L = findobj('-regexp', 'Tag', 'Peak\d|Width\d');
    if ~isempty(L)
        delete(L([L.Parent] == ax))
    end
end
    % ---------- SAVINGS -------------------
    function save_Figure(saveButton, ~, ax, n)
        data = guidata(saveButton);
        figure;
        targetAx = axes('Box', 'on', 'FontSize', 14);
        copyobj(ax.Children, targetAx)

        xlabel(targetAx, 'Time (ms)', 'FontSize', 16)
        ylabel(targetAx, 'Amplitude (V)', 'FontSize', 16)
        title(targetAx, sprintf('Level = %d dB', data(n).abr.level), 'FontSize', 20)
    end

    function save_allFigures(saveButton, ~)
        data = guidata(saveButton);
        N = length(data);
        x = floor(sqrt(N));
        allPlots = findobj('Type', 'Axes');
        
        allABRs = cat(1,data.abr);
        
        minAmp = allABRs.get_minAmplitude;
        maxAmp = allABRs.get_maxAmplitude;
        
        figure
        for n = 1:N
           ax = subplot(x, ceil(N/x), n); 

           copyobj(allPlots(n).Children, ax)

           ax.Box = 'on';
           ax.YLim = [minAmp maxAmp];

           title(ax, sprintf('Level = %d', data(n).abr.level))
           xlabel('Time')
           ylabel('Amplitude')
        end
    end

    function save_Points(saveButton, ~, n)
        data = guidata(saveButton);   

        waves = nan(10,2);
        waveIdx = 0;
        allCursorsData = getCursorInfo(data(1).dataCursorObj);
        if isempty(allCursorsData)
            msgbox('No points has been selected.', 'Missing selected data', 'error')
            return
        elseif mod(length(allCursorsData) , 2) ~= 0 % If the number of points selected is odd
            msgbox('An even number of points must be selected.', 'Missing selected data', 'error')
            return
        end

        for i = 1:length(allCursorsData)
            if strcmp(allCursorsData(i).Target.Parent.Tag, sprintf('Ax%d', n))
               waveIdx = waveIdx + 1;
               waves(waveIdx,:) = allCursorsData(i).Position;
            end
        end
        if waveIdx == 0
            msgbox('No points has been selected.', 'Missing selected data', 'error')
            return
        end
        waves(waveIdx+1:end,:) = [];
        waves = sortrows(waves);
        data(n).waves = waves;

        % Compute latencies
        latencies = [waves(2,1)-1.4e-3; diff(waves(2:2:end,1))];
        data(n).latencies = latencies;

        % Get amplitudes
        data(n).amplitudes = compute_Amplitudes(waves);

        % Update tables
        wavePointsTableObj = findobj('Tag', sprintf('wavePoints%d', n));
        amplitudesTableObj = findobj('Tag', sprintf('amplitudes%d', n));
        fill_Table(wavePointsTableObj, waves)
        fill_Table(amplitudesTableObj, [data(n).amplitudes data(n).latencies])
        amplitudesTableObj.RowName = compose('Wave %d', (1:length(data(n).amplitudes))');
        guidata(saveButton, data)
    end

    function export(exportButton, ~, n)
        data = guidata(exportButton);
        if isempty(data(n).waves)
            msgbox('No point has been selected and saved.', 'No saved points', 'error') 
            return        
        end


        % Get ABR vector
%         timepoints = data(n).timepoints;
%         abrVector = data(n).abr;

        % Get selected points
        selectedTimepoints = data(n).waves(:,1);
        amplitudes = data(n).waves(:,2);
        latencies = data(n).latencies;

        % Get corresponding amplitudes
        peak2peak = data(n).amplitudes;
        
        noiseLevel = data(n).abr.noiseLevel;
        % Format all data for excel sheet

        C = cell(data(n).abr.Npoints+1,7);

        C(1,1:7) = {'Time (ms)', 'Recorded ABR (mV)', 'Selected time points (ms)', 'Selected Amplitude (mV)', 'Peak to peak amplitude (mV)', 'Latencies (ms)', 'Noise Level (mV)'};
        C(2:end,1) = num2cell(Scale.convert_Units(data(n).abr.timeVector, data(n).abr.timeScale, Scale('m')));
        C(2:end,2) = num2cell(Scale.convert_Units(data(n).abr.amplitude, data(n).abr.ampScale, Scale('m')));

        C(2:2+length(selectedTimepoints)-1,3) = num2cell(Scale.convert_Units(selectedTimepoints, data(n).abr.timeScale, Scale('m')));    
        C(2:2+length(amplitudes)-1,4) = num2cell(Scale.convert_Units(amplitudes, data(n).abr.ampScale, Scale('m')));

        C(2:2+length(peak2peak)-1,5) = num2cell(Scale.convert_Units(peak2peak, data(n).abr.ampScale, Scale('m')));
        C(2:2+length(latencies)-1,6) = num2cell(Scale.convert_Units(latencies, data(n).abr.timeScale, Scale('m')));

        C(2:2+length(noiseLevel)-1, 7) = num2cell(Scale.convert_Units(noiseLevel, data(n).abr.ampScale, Scale('m')));
        % Ask whether the user wants to create a new file, or to save into an
        % existing one
        answer = questdlg('How do you want to save the file?', 'Choose a saving method'...
                        , 'Create a new file'...
                        , 'Save in a existing file' ...
                        , 'Create a new file'...
                        );

        switch answer
            case ''
                return
            case 'Create a new file'
                [filename, selpath] = uiputfile('*.xlsx');
                % Save as a new file

            case 'Save in a existing file'
                defaultPath = 'D:\DATOS\Thibaud\DRAFT';
                selpath = uigetdir(defaultPath, 'Select a folder to save');

                % Save in an existing file
                selPathContent = dir(selpath);
                files = selPathContent(~[selPathContent(:).isdir]);
                list = {files(:).name};
                idx = listdlg('ListString', list);
                filename = list{idx};
        end

        if ~isempty(filename)
            xlswrite(fullfile(selpath, filename), C, sprintf('%ddB', data(n).abr.level))
        end


    end

    function amps = compute_Amplitudes(waves)
        amps = zeros(round(length(waves)/2,1),1);
        ampIdx = 0;
        for i = 2:2:length(waves)        
                ampIdx = ampIdx + 1;
                amps(ampIdx) = waves(i,2)-waves(i-1,2);       
        end
    end

    function fill_Table(tableObj, values)
        tableObj.Data = num2cell(values);
    end


function update_unit(unitMenu, ~, n, dimension)
    data = guidata(unitMenu);
    targetAx = findobj('Tag', sprintf('Ax%d', n));
    newUnit = unitMenu.String{unitMenu.Value};

    targetAx.NextPlot = 'replace';
    data(n).abr.plot(targetAx, dimension, newUnit)
    
    % Restore axes properties
    targetAx.NextPlot = 'add';
    targetAx.Tag = sprintf('Ax%d', n);
    targetAx.FontSize = 14;
    
end

