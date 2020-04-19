function ABR_GUI(abrObj)
close all

fig = figure('Units','Normalized'...            
            ,'OuterPosition',[0 0 1 1]...
            );   

% Put edit shortcut in Edit menu
allMenus = findall(fig, 'Type', 'uimenu');
editMenu = findobj(allMenus, 'Tag', 'figMenuEdit');
shortcutMenu = uimenu(editMenu, 'Label', 'Edit Shortcuts'...
                              , 'Separator', 'on'...
                              , 'Callback', @edit_Shortcuts ...
                              );
                          
% jFrame = fig.JavaFrame;
% jFrame.setMaximized(1);

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
    [data, levels, frequencies] = initialize(abrObj);
    
    guidata(fig, data)
    generateTabs(fig, levels, frequencies);
    
end


end


function [data, levels, frequencies] = initialize(abrObj)
    Nabrs = numel(abrObj);
    
    % Reshape into levels x frequency
    levels = unique([abrObj.level]);
    frequencies = unique([abrObj.frequency]);
    
    Nlevels = length(levels);    
    if all(isnan(frequencies))
        Nfreq = 1;
    else
       Nfreq = length(frequencies); 
       
    end
    
    % Initialize data structure
    data(Nlevels, Nfreq) = struct('abr', []...
                        , 'waves', []...
                        , 'latencies', []...   
                        , 'peakDetectionSettings', []...
                        , 'shortcuts', [] ...
                         );  
     
   % Save abr objects in data structure                  
   for i = 1:Nabrs
       if all(isnan(frequencies))
           freqIdx = 1;
       else   
           freqIdx = abrObj(i).frequency == frequencies;
           
       end
       lvlIdx = abrObj(i).level == levels;
       
       % Fill in data structure
       data(lvlIdx, freqIdx).abr = abrObj(i);
           
   end
   
   
    % Delete potential previous plots
    tbGroup = findobj('Tag', 'tabGroup');
    delete(tbGroup)
    
    
   % Setup shortcuts from text file
   data = setup_Shortcuts(data);   
   mainFig = findobj('Type', 'Figure');
   shortcutTable = data(1).shortcuts;
   mainFig.KeyPressFcn = {@shortcut, shortcutTable};
end

function importFile(buttonObj, ~)
                       
    [file, path] = uigetfile('*.txt');
    if file == 0 % If users clicked "cancel" or closed the window
        return
    end
    
    filename = fullfile(path, file);
    
   abr = ABR.openFile(filename); 
   
   [data, levels, frequencies] = initialize(abr);
   
   

   importedFileLabel = findobj('Tag', 'importedFileLabel');
   importedFileLabel.String = file;
   
   
   
   guidata(buttonObj, data)
   generateTabs(buttonObj.Parent, levels, frequencies)
    
end


function generateTabs(parent, levels, frequencies)
    
    mainTabGp = uitabgroup(parent, 'Position', [0.02 0.02 .9 .85]...
                             , 'Tag', 'tabGroup'...
                             , 'TabLocation', 'left'...
                             );
    
    data = guidata(parent);
    Nlevels = length(levels);
    if all(isnan(frequencies))
        Nfreq = 1;
    else
        Nfreq = length(frequencies);
    end
    
    tabIdx = 0;
    for m = 1:Nfreq
        if Nfreq == 1
            tabParent = mainTabGp;
            color = [0 0 0];
        else
            tabColors = [252 13 140;
                         16 207 236;
                         49 232 36;
                         48 26 245] ./255;
            color = tabColors(m,:);
            
            freqTab = uitab(mainTabGp, 'Title', sprintf('%d Hz', frequencies(m))...
                                     , 'ForegroundColor', color);
            tabParent = uitabgroup(freqTab, 'TabLocation', 'left');
            
        end
        
        for n = 1:Nlevels
            tabIdx = tabIdx + 1;
            
            if isempty(data(n,m).abr)
                continue
            end
                
                tab = uitab(tabParent, 'Title', sprintf('%ddB', levels(n))...
                    ..., 'Tag', num2str(n)...
                    , 'ForegroundColor', color ...
                    ..., 'ButtonDownFcn', @test ...
                    , 'TooltipString', num2str(tabIdx) ...
                    );
            

            ax = axes(tab, 'Position', [0.08 0.1 0.6 0.7]...
                         , 'Box', 'on'...
                         , 'FontSize', 14 ...
                         , 'Tag',sprintf('Ax%d', tabIdx)...
                         , 'Ygrid', 'on'...
                         ..., 'ButtonDownFcn', @click_Ax ...
                         );
            hold on

            % Save Figure button
%             uicontrol(tab, 'Style', 'pushbutton'...
%                          , 'String', 'Save Figure'...
%                          , 'Units', 'Normalized'...
%                          , 'FontUnits', 'Normalized' ...
%                          , 'FontSize', 0.5 ...
%                          , 'Position', [ax.Position(1)+ax.Position(3)-0.1 0.9 0.1 0.05]...
%                          , 'Callback', {@save_Figure, ax, coord} ...
%                          );

            % Save points button         
%             uicontrol(tab, 'Style', 'pushbutton'...
%                          , 'String', 'Save Points'...
%                          , 'Units', 'Normalized'...
%                          , 'FontUnits', 'Normalized'...
%                          , 'FontSize', 0.5 ...
%                          , 'Position', [ax.Position(1)+ax.Position(3)-0.1 0.85 0.1 0.05]...
%                          , 'Callback', {@save_Points , coord}...
%                         );






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
                         , 'Callback', {@update_unit, tabIdx, 'timeunit'} ...
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
                         , 'Callback', {@update_unit, tabIdx, 'ampunit'} ...
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
                          , 'Callback', {@showNoise, tabIdx}...
                          );



            % Automatic peak detection
            peakAnalysisButton = uicontrol(tab, 'Style', 'pushbutton'...
                         , 'String', 'Peak Analysis'...
                         , 'Units', 'Normalized'...
                         , 'FontUnits', 'Normalized'...
                         , 'FontSize', 0.4 ...
                         , 'Position', [0.83,0.91,0.157,0.066]...
                         , 'Enable', 'on'...
                         , 'Tag', sprintf('peakAnalysisButton_%d', n)...
                         , 'Callback', {@open_PeakAnalysis, tabIdx} ...
                         );
                % Disable peak analysis button if amplitude less than 6e-6
                if max(data(n).abr.amplitude) < 6e-6
                   peakAnalysisButton.Enable = 'off'; 
                end

            data(n,m).abr.plot(ax);  

        end
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

function shortcut(mainFig, keydata, shortcutTable)
disp(keydata)
% if  strcmp(keydata.Key, 'a')
%     
%      % Get selected tab
%      tabGp = findobj(mainFig.Children,'Tag', 'tabGroup');
%      n = str2double(tabGp.SelectedTab.Tag);
%     peakAnalysisButton = findobj('Tag', sprintf('peakAnalysisButton_%d', n));
%     if strcmp(peakAnalysisButton.Enable, 'on')
%         open_PeakAnalysis(peakAnalysisButton, [], n)
%     end
% end

if strcmp(keydata.Key, shortcutTable.Keys(shortcutTable.Functions == "Open Peak Analysis Window"))
    % Get selected tab
    tabGp = findobj(mainFig.Children,'Tag', 'tabGroup');
    n = str2double(tabGp.SelectedTab.Tag);
    peakAnalysisButton = findobj('Tag', sprintf('peakAnalysisButton_%d', n));
    if strcmp(peakAnalysisButton.Enable, 'on')
        open_PeakAnalysis(peakAnalysisButton, [], n)
    end
end
    
end

function openOnCLick(tabSource, ~)

n = str2double(tabSource.Tag);
peakAnalysisButton = findobj('Tag', sprintf('peakAnalysisButton_%d', n));
if strcmp(peakAnalysisButton.Enable, 'on')
    open_PeakAnalysis(peakAnalysisButton, [], n)
end
end

function data = setup_Shortcuts(data)
shortcutFile = 'shortcuts.txt';
% importOptions = detectImportOptions(shortcutFile);
% importOptions.Whitespace = '';

[data.shortcuts] = deal(readtable(shortcutFile, 'Delimiter', ','));

end