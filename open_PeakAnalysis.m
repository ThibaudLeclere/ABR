function open_PeakAnalysis(button, ~, n)
    data = guidata(button);
    abrObj = data(n).abr;
    
    figName = sprintf('Peak Analysis: %s', abrObj.label);
    analysisFig = figure('Name', figName, 'KeyPressFcn', {@shortcut, n});
    analysisAx = axes(analysisFig, 'Position', [0.05 0.1 .6 .75]);    
    abrPlot = abrObj.plot(analysisAx);
    dataCursorObj = datacursormode(analysisFig);
    Brush = brush;
    Brush.ActionPostCallback = @(fig, axStruct) select_WaveFromBrush(fig, axStruct);
    
    analysisTabGroup = uitabgroup(analysisFig, 'Position', [analysisAx.Position(1) + analysisAx.Position(3) + 0.02...
                                                            0.20 ... Y
                                                            0.30 ... Width
                                                            0.75... Height
                                                            ]);
    
    %  ---------- Analysis Tab
    peakAnalysisTab = uitab(analysisTabGroup, 'Title', 'Auto detection');
    
        % Sliders for automatic detection
            % Default values
            detectionSettings.Npeaks = 4;
            detectionSettings.Height = 0;
            detectionSettings.Prominence = 0;
            detectionSettings.Threshold = 0;
            detectionSettings.Distance = 0;
            detectionSettings.Width = 0;
        
        % Sliders
        detectionFeatures = ["Npeaks", "Height", "Prominence", "Threshold", "Distance", "Width"];
        ranges = [1, 0, 0, 0, 0, 0;
                  8, 5, 5, 5, 5, 5];
        steps = repmat(1./(ranges(2,:)-ranges(1,:)), 2,1);
        
        yoffset = 0.1;
        for k = 1:length(detectionFeatures)
            label = uicontrol(peakAnalysisTab, 'Style', 'Text'...
                                        , 'String', sprintf('%s: 0', detectionFeatures(k)) ...
                                        , 'HorizontalAlignment', 'Left' ...
                                        , 'FontUnits', 'Normalized'...
                                        , 'FontSize', 0.7 ...
                                        , 'Units', 'Normalized'...
                                        , 'Position', [0.01, 0.90-(k-1)*yoffset, 0.3, 0.05]...
                                        );

            uicontrol(peakAnalysisTab, 'Style', 'slider'...
                                , 'Min', ranges(1,k) ...
                                , 'Max', ranges(2,k) ...
                                , 'SliderStep', [steps(1,k) steps(2,k)]...
                                , 'Value', detectionSettings.(detectionFeatures(k)) ...
                                , 'Units', 'Normalized'...
                                , 'Position', [0.4, 0.90-(k-1)*yoffset, 0.6, 0.04] ...
                                , 'Callback', {@set_DetectionSetting, label} ...
                                , 'Tag', sprintf('slider_%s', detectionFeatures(k)) ...
                                );
        end

        uicontrol(peakAnalysisTab, 'Units', 'Normalized'...
                                   , 'Position', [0.05 0.05 0.8 0.1]...
                                   , 'String', 'Detect Peaks'...
                                   , 'Callback', {@detect_Peaks, abrObj, dataCursorObj, abrPlot, detectionSettings} ...
                                   );
    % ----------------------------
    
    % --------- Waves Tab
    waveTab = uitab(analysisTabGroup, 'Title', 'Waves');
    
    % Display waves Checkbox
    uicontrol(waveTab, 'Style', 'Checkbox'...
                     , 'String', 'Display Waves'...
                     , 'Value', 0 ...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.7 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0.1 0.9 0.5 0.05]...
                     , 'Callback', {@display_Waves}...
                     );
    
    % Waves tables
    uitable(waveTab, 'ColumnName', {'Timepoints', 'Amplitudes'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.1 0.5 0.8 0.3]...
                   , 'Tag', sprintf('wavePoints%d', n)...
                   );   
               
    uitable(waveTab, 'ColumnName', {'Peak to peak amplitudes', 'Latencies'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.1 0.1 0.8 0.3]...
                   , 'Tag', sprintf('amplitudes%d', n)...
                   );
    % -----------------------------
   
        
    
    % -----------------------------
    % Save button
    uicontrol(analysisFig, 'Style', 'pushbutton'...
                         , 'String', 'Save points'...
                         , 'FontUnits', 'Normalized'...
                         , 'FontSize', 0.5 ...
                         , 'Units', 'Normalized'...
                         , 'Position', [analysisTabGroup.Position(1)... X
                                        analysisTabGroup.Position(2)-0.1 ... Y
                                        analysisTabGroup.Position(3)/2 ... Width
                                        0.1]... Height
                         , 'BackgroundColor', [0.7 0.9 0.7] ...
                         , 'Callback', {@save_Points, n} ...
                         , 'Tag', sprintf('savePtsBtn_%d', n) ...
                         )
    % Delete button
    uicontrol(analysisFig, 'Style', 'pushbutton' ...
                         , 'String', 'Delete all'...
                         , 'FontUnits', 'Normalized'...
                         , 'FontSize', 0.5 ...
                         , 'Units','Normalized'...
                         , 'Position', [analysisTabGroup.Position(1) + analysisTabGroup.Position(3)/2 ... X
                                        analysisTabGroup.Position(2)-0.1 ... Y
                                        analysisTabGroup.Position(3)/2 ... Width
                                        0.1] ... Height
                         , 'BackgroundColor', [1 0.5 0.5] ...
                         , 'Callback', {@delete_Datatips, dataCursorObj} ...
                         );
                     
    % Export button      
    uicontrol(analysisFig, 'Style', 'pushbutton'...
                     , 'String', 'Export'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.5 ...
                     , 'Position', [analysisTabGroup.Position(1)... X
                                        analysisTabGroup.Position(2)-0.2 ... Y
                                        analysisTabGroup.Position(3)/2 ... Width
                                        0.1]... Height
                     , 'BackgroundColor', [1 0.8 0.6] ...                     
                     , 'Tag', sprintf('exportBtn_%d', n) ...
                     , 'Callback', @export...
                    );                  
    % Analysis structure
    analysisData.abrObj = abrObj;
    analysisData.waves = [];
    analysisData.latencies = [];
    analysisData.WavesIllustration = [];
    analysisData.detectionSettings = detectionSettings;
    guidata(analysisFig, analysisData)
end
% ----------- PEAK DETECTION ------------------
function detect_Peaks(detectButton, ~, abrObj,  dataCursorObj, abrPlot)
% if nargin < 5 || isempty(settings)
%     settings.Npeaks = 4;
%     settings.Threshold = 0;
%     settings.MinPeakDistance = 0;
%     settings.MinPeakWidth = 0;
%     settings.MinPeakProminence = 0;
%     settings.MinPeakHeight = 0;
% end
    analysisData = guidata(detectButton);
    
    abrSig = abrObj.amplitude;

    t = abrObj.timeVector;
    noiseLevel = abrObj.noiseLevel;
  
    timeLimit = 1.3e-3;
    
    
    % Get positive peaks
    [peaks, locs] = findpeaks(abrSig(t>timeLimit), t(t>timeLimit) ...
                                                , 'MinPeakHeight', noiseLevel(1)...
                                                , 'MinPeakProminence', analysisData.detectionSettings.Prominence ...
                                                , 'NPeaks', analysisData.detectionSettings.Npeaks ... 
                                                , 'Threshold', analysisData.detectionSettings.Threshold ...
                                                , 'MinPeakDistance', analysisData.detectionSettings.Distance...
                                                , 'MinPeakWidth', analysisData.detectionSettings.Width ...
                                                );
                                    
    
    
    % Get negative peaks
    [negPeaks, negLocs] = findpeaks(-abrSig(t>timeLimit), t(t>timeLimit)...
                                                         , 'MinPeakHeight', -noiseLevel(2)...
                                                         , 'MinPeakProminence', analysisData.detectionSettings.Prominence ...
                                                         , 'NPeaks', analysisData.detectionSettings.Npeaks ...
                                                         , 'Threshold', analysisData.detectionSettings.Threshold ...
                                                         , 'MinPeakDistance', analysisData.detectionSettings.Distance...
                                                         , 'MinPeakWidth', analysisData.detectionSettings.Width ...
                                                         );
                                           
    
    
    % Create datatip
    if verLessThan('Matlab', '9.7')
        % Positive peaks   
        for i = 1:length(peaks)
            posTip = dataCursorObj.createDatatip(abrPlot);
            posTip.Position = [locs(i), peaks(i)];
        end
        
        % Negative peaks
        for j = 1:length(negPeaks)
            negTip = dataCursorObj.createDatatip(abrPlot);
            negTip.Position = [negLocs(j), -negPeaks(j)];
        end
    else
        for i = 1:length(peaks)
          datatip(abrPlot, locs(i), peaks(i));
        end
        for j = 1:length(negPeaks)
          datatip(abrPlot, negLocs(j), -negPeaks(j));
        end


    end
      
    
end
function select_WaveFromBrush(fig, axStruct)
%     data = guidata(fig);
    
    ax = axStruct.Axes;
    abrPlot = findobj(ax, '-regexp', 'Tag', 'recording_\d*');
      
    
    idx = logical(abrPlot.BrushData);
%     
    if any(idx)
        disp('Selection has been made with the brush')
        t = abrPlot.XData;
        amp = abrPlot.YData;        
        
        brushSelection = [t(idx) ; amp(idx)];
        
        % Select min and max values within the selection with respect to
        % the amplitude
        [~, minIdx] = min(brushSelection(2,:));
        [~, maxIdx] = max(brushSelection(2,:));
%         
        if verLessThan('Matlab', '9.7') % The datatip command doesn't exist before Matlab 2019b
            cursor = datacursormode(fig);
            
            dtMin = cursor.createDatatip(abrPlot);
            dtMax = cursor.createDatatip(abrPlot);

            dtMin.Position = [brushSelection(1, minIdx), brushSelection(2, minIdx)];
            dtMax.Position = [brushSelection(1, maxIdx), brushSelection(2, maxIdx)];
        else
            datatip(abrPlot, brushSelection(1, minIdx), brushSelection(2, minIdx));
            datatip(abrPlot, brushSelection(1, maxIdx), brushSelection(2, maxIdx));
        end
    end
end
function set_DetectionSetting(sliderObj, ~, labelObj)
   
    analysisData = guidata(sliderObj);    
    
    feature = extractAfter(sliderObj.Tag, '_');
    
    % Set prominence value in the data structure 
    analysisData.detectionSettings.(feature) = sliderObj.Value;
    
    % Update slider label
    update_Label(labelObj, sliderObj.Value)
%     label = findobj('Tag', sprintf('prominenceSliderLabel%d', n));
%     label.String = num2str(sliderObj.Value);
    
    guidata(sliderObj, analysisData)
    
%     ax = findobj('Tag', sprintf('Ax%d', n));
%     clean_Peaks(ax)
%     detect_Peaks(sliderObj, [], ax, n)
end

function update_Label(labelObj, val)
    setting = extractBefore(labelObj.String, ':');
    setting = replace(setting, ' ', '');
    labelObj.String = join([setting, ":", num2str(val)]);
    
end

function delete_Datatips(~, ~, dataCursorObj)
% Ask confirmation
    answer = questdlg('Are you sure you want to delete all datatips?', 'Delete datatips', 'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        removeAllDataCursors(dataCursorObj)
    else
        return
    end

end

function save_Points(saveButton, ~, n)
%         data = guidata(saveButton);   
        analysisData = guidata(saveButton);
        fig = saveButton.Parent;
        
        % Access to datatips
        dataCursorObj = datacursormode(fig);
        allDatatips = getCursorInfo(dataCursorObj);
        
        % Preallocate waves vector
        waves = nan(length(allDatatips),2);
                
        if isempty(allDatatips)
            msgbox('No points has been selected.', 'Missing selected data', 'error')
            return
        elseif mod(length(allDatatips) , 2) ~= 0 % If the number of points selected is odd
            msgbox('An even number of points must be selected.', 'Missing selected data', 'error')
            return
        end

        for i = 1:length(allDatatips)
               waves(i,:) = allDatatips(i).Position;%             
        end
        
        
        waves = sortrows(waves);
        analysisData.waves = waves;

        % Compute latencies
        latencies = [waves(2,1)-1.4e-3; diff(waves(2:2:end,1))];
        analysisData.latencies = latencies;

        % Get amplitudes
        analysisData.amplitudes = compute_Amplitudes(waves);

        % Update tables
        wavePointsTableObj = findobj('Tag', sprintf('wavePoints%d', n));
        amplitudesTableObj = findobj('Tag', sprintf('amplitudes%d', n));
        fill_Table(wavePointsTableObj, waves)
        fill_Table(amplitudesTableObj, [analysisData.amplitudes analysisData.latencies])
        amplitudesTableObj.RowName = compose('Wave %d', (1:length(analysisData.amplitudes))');
        guidata(saveButton, analysisData)
end
% ---------- WAVES ------------------
function display_Waves(button, ~)
analysisData = guidata(button);

if isempty(analysisData.waves)
    disp('No points were saved')
    return
end

if isempty(analysisData.WavesIllustration)
    analysisData.WavesIllustration = gobjects(0);

    % Lines on peaks
%     for i = 1:size(analysisData.waves, 1)
%         analysisData.WavesIllustration(i) = line([analysisData.waves(i,1) analysisData.waves(i,1)], [0 analysisData.waves(i,2)], 'LineStyle', '--');
%     end
    
    % Patch for each wave
    colors = [0 0.4470 0.7410;
              0.8500 0.3250 0.0980;
              0.9290 0.6940 0.1250;
              0.4940 0.1840 0.5560;
              0.4660 0.6740 0.1880;
              0.3010 0.7450 0.9330;
              0.6350 0.0780 0.1840];
    for j = 1:2:size(analysisData.waves, 1)-1
        x = [analysisData.waves(j,1) analysisData.waves(j,1)  analysisData.waves(j+1,1) analysisData.waves(j+1,1)];
        y = [analysisData.waves(j,2) analysisData.waves(j+1,2) analysisData.waves(j+1,2) analysisData.waves(j,2)];
        p = patch(x, y, colors((j+1)/2,:), 'FaceAlpha', 0.3);
        str = sprintf('WAVE %d', (j+1)/2);
        t = text(analysisData.waves(j,1), analysisData.waves(j+1,2) + 5e-6, str, 'Color', colors((j+1)/2,:), 'VerticalAlignment', 'top');
        analysisData.WavesIllustration = cat(2,analysisData.WavesIllustration, p, t);
    end

else
    switch button.Value
        case 0
            set(analysisData.WavesIllustration, 'Visible', 'off')
        case 1
            set(analysisData.WavesIllustration, 'Visible', 'on')
    end
    
    
end

guidata(button, analysisData)
end
% ---------- EXPORT -----------------
function export(exportButton, ~)
        analysisData = guidata(exportButton);
        if isempty(analysisData.waves)
            msgbox('No point has been selected and saved.', 'No saved points', 'error') 
            return        
        end


        % Get selected points
        selectedTimepoints = analysisData.waves(:,1);
        amplitudes = analysisData.waves(:,2);
        latencies = analysisData.latencies;

        % Get corresponding amplitudes
        peak2peak = analysisData.amplitudes;
        
        noiseLevel = (analysisData.abrObj.noiseLevel)';
        
        % Convert vectors in ms and mV
        time = Scale.convert_Units((analysisData.abrObj.timeVector)', analysisData.abrObj.timeScale, Scale('m'));
        amp = Scale.convert_Units(analysisData.abrObj.amplitude, analysisData.abrObj.ampScale, Scale('m'));
        selTimePoints = Scale.convert_Units(selectedTimepoints, analysisData.abrObj.timeScale, Scale('m'));
        selAmplitudes = Scale.convert_Units(amplitudes, analysisData.abrObj.ampScale, Scale('m'));
        peak2peak = Scale.convert_Units(peak2peak, analysisData.abrObj.ampScale, Scale('m'));
        latencies = Scale.convert_Units(latencies, analysisData.abrObj.timeScale, Scale('m'));
        noiseLevel = Scale.convert_Units(noiseLevel, analysisData.abrObj.ampScale, Scale('m'));
        
        % Pad with NaN to get the same vector length
        selTimePoints = [selTimePoints; nan(length(time)-length(selTimePoints), 1)];
        selAmplitudes = [selAmplitudes; nan(length(time)-length(selAmplitudes), 1)];
        peak2peak = [peak2peak; nan(length(time)-length(peak2peak), 1)];
        latencies = [latencies; nan(length(time)-length(latencies), 1)];
        noiseLevel = [noiseLevel; nan(length(time)-length(noiseLevel), 1)];
        
        % Create table
        T = table(time, amp, selTimePoints, selAmplitudes, peak2peak, latencies, noiseLevel);
        colNames = ["Time", "Amplitude", "SelectedTimes", "SelectedAmplitudes", "Peak2Peak", "Latencies", "NoiseLevel"];
        units = ["ms", "mV", "ms", "mV", "mV", "ms", "mV"];
        varNames = (compose("%s (%s)", colNames', units'))';
        
        if verLessThan('matlab', '9.7')            
            % Pass a string array for VariableNames is not allowed before MATLAB 9.5 (2018b)
            % Also variable names must be valid (isvarname returning true),
            % so inserting units is not possible.
            T.Properties.VariableNames = cellstr(colNames);
        else
            T.Properties.VariableNames = varNames;
        end
        
        
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
                [filename, selectedPath] = uiputfile({'*.xlsx'; '*.xls'; '*.csv'});
                

            case 'Save in a existing file'  
                [filename, selectedPath] = uigetfile({'*.xlsx'; '*.xls'; '*.csv'});
        end
        
        
        % Use Writetable to export (proved to work on a Mac computer)
        try
            writetable(T, fullfile(selectedPath, filename), 'Sheet', analysisData.abrObj.label)
        catch ME
            msgbox(sprintf('An error occurred when exporting ABRs:\n %s', ME.message), '', 'error')
        end
  
    end


    function amps = compute_Amplitudes(waves)
        amps = zeros(round(length(waves)/2,1),1);
        ampIdx = 0;
        for i = 2:2:length(waves)        
                ampIdx = ampIdx + 1;
                amps(ampIdx) = waves(i,2)-waves(i-1,2);       
        end
        
        if any(amps < 0)
           msgbox('At least one wave maplitude is negative. Check your selected peaks.', 'Negative amplitude', 'warn') 
        end
        
    end

    function fill_Table(tableObj, values)
        tableObj.Data = num2cell(values);
    end
    
    
% ---------- SHORTCUTS -------------
function shortcut(analysisFig, keydata, n)

    if ~isempty(keydata.Modifier) && strcmp(keydata.Modifier{1}, 'control') && strcmp(keydata.Key, 'e')
       exportButton = findobj('Tag', sprintf('exportBtn_%d', n));
       export(exportButton, [])

    end

    if strcmp(keydata.Key, 's')
       savePointsButton = findobj('Tag', sprintf('savePtsBtn_%d', n));
       save_Points(savePointsButton, [], n)

    end

    if strcmp(keydata.Key, 'delete')   
       dataCursorObj = datacursormode(analysisFig);
       delete_Datatips([], [], dataCursorObj)

    end

end