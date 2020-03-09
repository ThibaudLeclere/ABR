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
        
        
          
                
        
         
        % Change timeunit
        uicontrol(tab, 'Style', 'text'...
                     , 'String', 'Time Units'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.25 ...
                     , 'Units', 'Normalized'...
                     , 'Position', [0 0.9 0.1 0.1]...
                     )
                 
        uicontrol(tab, 'Style', 'popupmenu'...
                     , 'String', {'�s', 'ms', 's'}...
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
                     , 'String', {'�V', 'mV', 'V'}...
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
%         peakPanel = uipanel(tab, 'Position', [0.73,0.55,0.25,0.45]);
%         
%         % Sliders
%         peakDetectionSettings = ["Npeaks", "Height", "Prominence", "Threshold", "Distance", "Width"];
%         ranges = [1, 0, 0, 0, 0, 0; 
%                   8, 5, 5, 5, 5, 5];
%         steps = repmat(1./(ranges(2,:)-ranges(1,:)), 2,1);
%         
%         yoffset = 0.1;
%         for k = 1:length(peakDetectionSettings)
%             label = uicontrol(peakPanel, 'Style', 'Text'...
%                                         , 'String', sprintf('%s: 0', peakDetectionSettings(k)) ...
%                                         , 'HorizontalAlignment', 'Left' ...
%                                         , 'FontUnits', 'Normalized'...
%                                         , 'FontSize', 0.8 ...
%                                         , 'Units', 'Normalized'...
%                                         , 'Position', [0.01,0.90-(k-1)*yoffset,0.45,0.09]...
%                                         );
% 
%             uicontrol(peakPanel, 'Style', 'slider'...
%                                 , 'Min', ranges(1,k) ...
%                                 , 'Max', ranges(2,k) ...
%                                 , 'SliderStep', [steps(1,k) steps(2,k)]...
%                                 , 'Value', 4 ...
%                                 , 'Units', 'Normalized'...
%                                 , 'Position', [0.5,0.90-(k-1)*yoffset,0.45,0.05] ...
%                                 , 'Callback', {@set_DetectionSetting, label, n} ...
%                                 , 'Tag', sprintf('slider_%s', peakDetectionSettings(k)) ...
%                                 );
%         end
                       
        % Automatic peak detection
        uicontrol(tab, 'Style', 'pushbutton'...
                     , 'String', 'Peak Analysis'...
                     , 'Units', 'Normalized'...
                     , 'FontUnits', 'Normalized'...
                     , 'FontSize', 0.4 ...
                     , 'Position', [0.83,0.91,0.157,0.066]...
                     , 'Callback', {@open_PeakAnalysis, n} ...
                     );
                 
%         data(n).dataCursorObj = datacursormode(parent);       
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

