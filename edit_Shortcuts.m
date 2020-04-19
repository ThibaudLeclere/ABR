function edit_Shortcuts(menuObj, actionData)
disp('Edit shortcuts')
shortcutFig = figure('Name', 'Shortcut Edition'...
                    ..., 'CloseRequestFcn', {@setup_Shortcuts, data}
                        );
data = struct();

% Create table from shortcut file
data.shortcutFile = 'shortcuts.txt';
shortTable = readtable(data.shortcutFile, 'Delimiter', ',');
shortcutFromFile = table2cell(shortTable);
uitable(shortcutFig, 'Data', shortcutFromFile...
                    , 'ColumnName', shortTable.Properties.VariableNames ... 
                    , 'Units', 'Normalized'...
                   ,'Position', [0 0 0.5 0.5]...
                   , 'CellSelectionCallback', @select_Cell ...
                   ..., 'CellEditCallback', @edit_Cell ...
                   , 'ColumnEditable', [false, false]...
                   , 'KeyPressFcn', @change_Key ...
                   );


guidata(shortcutFig, data)
end
function select_Cell(shortTable, cellSelection)
if isempty(cellSelection.Indices)
   return 
end
fprintf('Cell selected (%d, %d)\n', cellSelection.Indices(1), cellSelection.Indices(2))
data = guidata(shortTable);
data.cellSelection = cellSelection;

guidata(shortTable, data)

end
% function edit_Cell(shortTable, cellEdition)
% disp('Edit Cell')
% disp(cellEdition)
% 
% 
% % f = msgbox('Type new shortcut');
% % f.HitTest = 'off';
% % keyboard
% end

function change_Key(shortTable, event)
disp('Key pressed')
if isempty(event.Key)
    disp('Empty key')
    return
end
data = guidata(shortTable);
if data.cellSelection.Indices(2) == 2 && strcmp(data.cellSelection.EventName, 'CellSelection')
      
    if isempty(event.Modifier)
        shortTable.Data{data.cellSelection.Indices(1), data.cellSelection.Indices(2)} = event.Character;
        
    elseif ~strcmp(event.Modifier{1}, event.Key)       
        fprintf('%s + %s\n', event.Modifier{1}, event.Key)
        shortTable.Data{data.cellSelection.Indices(1), data.cellSelection.Indices(2)} = sprintf('%s + %s', event.Modifier{1}, event.Key);
    end
end

% Update shortcut file
t = cell2table(shortTable.Data, 'VariableNames', shortTable.ColumnName);
writetable(t,data.shortcutFile)
end