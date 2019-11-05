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
                     , 'Position', [ax.Position(1)+ax.Position(3)+0.1 0.85 0.1 0.05]...
                     , 'Callback', {@export , n}...
                    );    
                
        uitable(tab, 'ColumnName', {'Timepoints', 'Amplitudes'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.73 0.1 0.25 0.4]...
                   , 'Tag', sprintf('wavePoints%d', n)...
                   );   
               
        uitable(tab, 'ColumnName', {'Peak to peak amplitudes', 'Latencies'}...
                   , 'ColumnEditable', false...
                   , 'Units', 'Normalized'...
                   , 'Position', [0.73 0.52 0.25 0.2]...
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
        uicontrol(tab, 'Style', 'Text'...
                     , 'String', sprintf('Noise Confidence Interval (V): [%f %f]', data(n).abr.noiseLevel(1), data(n).abr.noiseLevel(2))...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.5 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0.184829833454017,0.93,0.359956553222301,0.048139240506329]...
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
    lines = findobj(currentAx, 'Tag', sprintf('noiseLevel'));
    [lines.Visible] = deal(show);
    
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
        
        % Loop through all cursordata objects and only select those
        % corresponding to the current axes
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


        % Get selected points
        selectedTimepoints = data(n).waves(:,1);
        amplitudes = data(n).waves(:,2);
        latencies = data(n).latencies;

        % Get corresponding amplitudes
        peak2peak = data(n).amplitudes;
        
        noiseLevel = (data(n).abr.noiseLevel)';
        
        % Convert vectors in ms and mV
        time = Scale.convert_Units((data(n).abr.timeVector)', data(n).abr.timeScale, Scale('m'));
        amp = Scale.convert_Units(data(n).abr.amplitude, data(n).abr.ampScale, Scale('m'));
        selTimePoints = Scale.convert_Units(selectedTimepoints, data(n).abr.timeScale, Scale('m'));
        selAmplitudes = Scale.convert_Units(amplitudes, data(n).abr.ampScale, Scale('m'));
        peak2peak = Scale.convert_Units(peak2peak, data(n).abr.ampScale, Scale('m'));
        latencies = Scale.convert_Units(latencies, data(n).abr.timeScale, Scale('m'));
        noiseLevel = Scale.convert_Units(noiseLevel, data(n).abr.ampScale, Scale('m'));
        
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
        
        if verLessThan('matlab','9.5')
            % Pass a string array for VariableNames is not allowed before MATLAB 9.5 (2018b)
            T.Properties.VariableNames = cellstr(varNames);
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
            writetable(T, fullfile(selectedPath, filename), 'Sheet', data(n).abr.label)
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

