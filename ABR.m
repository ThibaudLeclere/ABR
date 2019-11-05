classdef ABR
    properties (SetAccess = private)
        amplitude = [];
        fs 
        level
        side
        subjectID
        label = "";
        timeUnit = 's';
        ampUnit = 'V';
        timeScale = Scale('unit');
        ampScale = Scale('unit');
    end
    
    properties (Dependent = true)
        timeVector
        Npoints
        noiseLevel
    end
    
    
    methods
        
        % Constructor
        function abrObj = ABR(varargin)            
            for i = 1:2:length(varargin)
               abrObj.(varargin{i}) = varargin{i+1}; 
            end
            
            % Make sure that amplitude is a column vector
            if ~iscolumn(abrObj.amplitude)
               
                if isvector(abrObj.amplitude) || isempty(abrObj.amplitude)
                   abrObj.amplitude = transpose(abrObj.amplitude);
                else                                        
                     error('Amplitude property must be a vector')
                end                                
            end
            
        end        
        function export(abrObj, filename)
            % Saves the ABR array in an excel sheet
            %   Time is represented in lines of the excel sheet
            %   Dimension one is represented as columns of the excel sheet
            %   Other dimensions are represented as sheets

            
            [filepath, ~, ext] = fileparts(filename);
            if isempty(ext) % If no extension has been entered
                ext = 'xlsx';
            end
            
            maxNpoints = max([abrObj.Npoints]);
            
           
           
            % Get abr amplitudes in a table
            Nabr = numel(abrObj);
            
                % Preallocation
                exportTable = table('Size', [maxNpoints, Nabr+1], 'VariableTypes', repmat("double", 1, Nabr + 1));
                exportTable{:,1} = (abrObj(1).timeVector)';
                
            for i = 1:size(abrObj,1)
                % Padd with NaN if necessary
                ampVector = abrObj(i).amplitude;
                
                if length(ampVector) ~= maxNpoints
                   ampVector =  [ampVector; nan(maxNpoints - length(ampVector),1)];
                end
                exportTable{:,i+1} = ampVector;
            end
            
            % Labels
            varNames = ["Time", [abrObj.label]];
            units = join([string({abrObj(1).timeScale abrObj.ampScale}); string({abrObj(1).timeUnit abrObj.ampUnit})],1);
            units = erase(units, [" ", "unit"]);
            
            exportTable.Properties.VariableNames = (compose("%s (%s)", varNames', units'))';

            
            try
                writetable(exportTable, filename)
                msgbox(sprintf('ABRs exported with success in %s', fullfile(filepath, [filename '.' ext])), 'ABR exported')
            catch ME
                msgbox(sprintf('An error occurred when exporting ABRs:\n %s', message.message), '', 'error')
            end

        end   
        
        function openInGUI(abrObj)
            ABR_GUI(abrObj)
        end
        
        function plot(abrObj, varargin)
            plotProperties = varargin;
            if ~isempty(varargin) && isa(varargin{1}, 'matlab.graphics.axis.Axes')
                ax = varargin{1};                
                plotProperties(1) = [];
                createFigFlag = false;  
            else
                createFigFlag = true;
            end
            
            
            timeunitIdx = cellfun(@(x) strcmpi(x, 'timeunit'), plotProperties);
            ampunitIdx = cellfun(@(x) strcmpi(x, 'ampunit'), plotProperties);
            YlimitsIdx = cellfun(@(x) strcmpi(x, 'YLim'), plotProperties);
            XlimitsIdx = cellfun(@(x) strcmpi(x, 'XLim'), plotProperties);
            
            if all(~timeunitIdx)
                timeunit = 's';
            else
                timeunit = plotProperties{find(timeunitIdx)+1};
            end
            timeunitIdx(find(timeunitIdx)+1) = 1;
            
            
            if all(~ampunitIdx)
                ampunit = 'V';
            else
                ampunit = plotProperties{find(ampunitIdx)+1};
            end
            ampunitIdx(find(ampunitIdx) + 1) = 1;
            
            if any(XlimitsIdx)
                xlim = plotProperties{find(XlimitsIdx)+1};
                XlimitsIdx(find(XlimitsIdx) + 1) = 1;
            else
                xlim = [-Inf Inf];
            end
            
            if any(YlimitsIdx)
                ylim = plotProperties{find(YlimitsIdx)+1};
                YlimitsIdx(find(YlimitsIdx) + 1) = 1;
            else
                ylim = [-Inf Inf];
            end
            
            plotProperties = plotProperties(~(timeunitIdx + ampunitIdx + YlimitsIdx + XlimitsIdx));
            
            Nabrs = numel(abrObj);
            for n = 1:Nabrs
                if createFigFlag
                    figure('Name', abrObj(n).label)
                    ax = axes;
                end
                % Convert time units
                timePrefix = ABR.get_UnitPrefix(timeunit);
                t = Scale.convert_Units(abrObj(n).timeVector, abrObj(n).timeScale, Scale.(timePrefix));
                
                % Convert amplitude units
                ampPrefix = ABR.get_UnitPrefix(ampunit);
                amp = Scale.convert_Units(abrObj(n).amplitude, abrObj(n).ampScale, Scale.(ampPrefix));
                noiseLvl = Scale.convert_Units(abrObj(n).noiseLevel, abrObj(n).ampScale, Scale.(ampPrefix));
                
                plot(ax, t, amp, plotProperties{:})
                
                ax.XLabel.String = sprintf('Time (%s)', timeunit);
                ax.XLabel.FontSize = 16;
                
                ax.YLabel.String = sprintf('Amplitude (%s)', ampunit);
                ax.YLabel.FontSize = 16;
                
                ax.Title.String =  abrObj(n).label;
                ax.Title.FontSize = 20;
                ax.Title.Interpreter =  'none';
                ax.YGrid = 'on';
                
                % Line of the recording delay
%                 sampleLimit = ceil(1e-3 * abrObj(n).fs) + 1;
                recordingDelay = 1.4414; %ms
                recordingDelay = Scale.convert_Units(recordingDelay, Scale('m'), Scale(timePrefix));
                line(ax,[recordingDelay recordingDelay], [min(amp) max(amp)]...
                               , 'LineStyle', '--'...
                               , 'Color', 'k'...
                               )
                 % Line of Y=0
                line(ax,get(ax, 'XLim'), [0 0]...
                            , 'LineStyle', '-'...
                            , 'Color', [0.3 0.3 0.3]...
                            )
                 % Noise confidence intervals
                 for i = 1:2
                     line(ax, [t(1) t(end)]...
                            , [noiseLvl(i) noiseLvl(i)]...
                            , 'Color', 'r'...
                            , 'LineStyle', '--'...
                            , 'Tag', 'noiseLevel'...
                            )
                 end
                 % Set axes limits
                 set(ax, 'XLim', xlim)
                 set(ax, 'YLim', ylim)
                 
                 
            end
            
           
        end
        function result = plus(abrObj1, abrObj2)
            result = sum([abrObj1, abrObj2]);
        end
        function s = sum(abrArray)
           
           % Convert all objects in seconds and A
           [abrArray.timeScale] = deal(Scale('unit'));
           [abrArray.ampScale] = deal(Scale('unit'));
            allTimeVectors = {abrArray.timeVector};
            
            % Make sure all ABRs have the same time vectors
            if ~isequal(allTimeVectors{:})
               error('All ABRs must have the same time vector.')  
            end
            newLevel = [];
            newSide = '';
            newSubjectID = '';
            newLabel = '';
            
            sumAmplitude = sum(cat(2, abrArray.amplitude),2);
            
            s = ABR('amplitude', sumAmplitude ...
                     ,'fs', abrArray(1).fs ... in theory, if timeVector are all the same, so are fs
                     ,'level', newLevel ... how to deal with that?
                     ,'side', newSide ... how to deal with that?
                     ,'subjectID', newSubjectID ...how to deal with that?
                     ,'label', newLabel... what label?
                     , 'timeUnit', 's'...
                     , 'ampUnit', 'V'...
                     , 'timeScale', Scale('unit')...
                     , 'ampScale', Scale('unit')...
                     );
        end
        function averagedABR = mean(abrArray, newLabel)
             % Convert all objects in seconds and V        
           [abrArray.timeScale] = deal(Scale('unit'));
           [abrArray.ampScale] = deal(Scale('unit'));
           
            % Make sure all ABRs have the same time vectors
            allTimeVectors = {abrArray.timeVector};
            
            if ~isequal(allTimeVectors{:})
               error('All ABRs must have the same time vector.')  
            end
            
            if nargin < 2
                newLabel = 'average';
            end
            allLevels =  [abrArray.level];
            allSides = {abrArray.side};
            allSubjectID = {abrArray.subjectID};
            
            if isscalar(unique((allLevels)))
                newLevel = abrArray(1).level;
            else
                newLevel = NaN;
            end
            
            if isequal(allSides{:})
                newSide = abrArray(1).side;
            else
                newSide = NaN;
            end
            
            if isequal(allSubjectID{:})
                newSubjectID = abrArray(1).subjectID;
            else
                newLevel = NaN;
            end
            
            averagedAmplitude = mean(cat(2, abrArray.amplitude),2);
            
            averagedABR = ABR('amplitude', averagedAmplitude ...
                             ,'fs', abrArray(1).fs ... in theory, if timeVector are all the same, so are fs
                             ,'level', newLevel ... how to deal with that?
                             ,'side', newSide ... how to deal with that?
                             ,'subjectID', newSubjectID ...how to deal with that?
                             ,'label', newLabel... what label?
                             );
            
        end
        
        
        % ---------- DEPENDENT PROPERTIES
        function timeVector = get.timeVector(abrObj)
            timeVector = (0:abrObj.Npoints-1)/abrObj.fs;
            timeVector = Scale.convert_Units(timeVector, Scale.unit, abrObj.timeScale);
        end
        
        function Npoints = get.Npoints(abrObj)
            Npoints = length(abrObj.amplitude);
        end
        
        function noiseConfidentInterval = get.noiseLevel(abrObj)

        timeLimit = 1e-3; % 1ms
        sampleLimit = ceil(timeLimit * abrObj.fs) + 1;

%         Scale.convert_Units(abrObj.amplitude(1:sampleLimit), abrObj.ampScale)
        av = mean(abrObj.amplitude(1:sampleLimit));
        sd = std(abrObj.amplitude(1:sampleLimit));

        % Confidence interval of noise
        noiseConfidentInterval = [av + 2*sd,  av - 2*sd];    
        end
               
        function minAmp = get_minAmplitude(abrArray)
            allAmplitudes = cat(1,abrArray.amplitude);
            minAmp = min(allAmplitudes);
        end
        
        function maxAmp = get_maxAmplitude(abrArray)
            allAmplitudes = cat(1,abrArray.amplitude);
            maxAmp = max(allAmplitudes);
        end
    end
    
    methods (Static = true)  
        function abrObj = openFile(filename, label)
            if nargin < 1
                [file, path] = uigetfile('*.txt', 'MultiSelect', 'off');
                filename = fullfile(path, file);
            end            
            
            % Read the entire file
            fileData = ABR.read_ABRfromFile(filename);
            
            % Determine levels
            [levels, Nlevels] = ABR.get_Levels(fileData);
            
            % Get line indicating subjectID
            subjectIDline = ~cellfun(@isempty, regexp(fileData, 'Subject ID:'));
            subjectIDtxt = strrep(fileData(subjectIDline), ' ', '');
            s = split(subjectIDtxt, 'SubjectID:');
            subjectID = s(2);
            
            % Get line indicating the side
            sideLine = ~cellfun(@isempty, regexp(fileData, 'Reference #1:'));
            sideLinetxt = strrep(fileData(sideLine), ' ', '');
            s = split(sideLinetxt, 'Reference#1:');
            side = s(2);
                  
            % Get line indicating the duration
            [durations, ~] = ABR.get_Durations(fileData);
            
            % Get line indicating the number of points
            Npoints = ABR.get_Npoints(fileData);
            
            % Determine sample rate
            fs = Npoints./(durations*1e-3);
            
            % Preallocate abr output object
            abrObj(Nlevels,1) = ABR();
            
            % Get levels and measurement values
            a = diff(~isnan(double(fileData)));
            idxStart = find(a == 1) + 1;
            idxEnd = find(a == -1);
            for i = 1:Nlevels
                dataIdx = idxStart(i):idxEnd(i);
                
                
                abrAmplitude = double(fileData(dataIdx));
                abrLevel = levels(i);
                abrFs = fs(i);
                
                % Create label
                if nargin < 2
                    [~, name, ~] = fileparts(filename);
                    label = sprintf("%s_%ddB", name, abrLevel);
                end
                
                abrObj(i) = ABR('amplitude', abrAmplitude...
                              , 'level', abrLevel...
                              , 'fs', abrFs ...
                              , 'side', side...
                              , 'subjectID', subjectID...
                              , 'label', label...
                              );
                
            end
            
            % Check all recordings have the same number of points            
            if ~isscalar(unique([abrObj.Npoints]))
                msgbox('Number of points differ across recordings', 'Number of points differ', 'warning')
            end
            
        end
        
        function prefix = get_UnitPrefix(targetUnit)
            prefix = char(regexp(targetUnit, 'unit||\<da||\<[pnµumcdhkMGT]', 'match'));
            if strcmp(prefix, 'µ')
                    prefix = 'u';
            end
            if isempty(prefix)
                prefix = 'unit';
            end
        end
        
        function fileData = read_ABRfromFile(filename)
            fid = fopen(filename, 'r');
            l = 0;
            txt = '';
            fileData = string(1);
            while ischar(txt)
                l = l + 1;
                txt = fgetl(fid);
                fileData(l,:) = string(txt);
                % TODO: account that old versions of Matlab don't have
                % string classes
            end
            fclose(fid);
        end
        
        function [levels, Nlevels] = get_Levels(fileData)
            % Get lines indicating Levels
            levelLines = ~cellfun(@isempty, regexp(fileData, 'Level'));
            levelsTxt = strrep(fileData(levelLines), ' ', '');
            
            Nlevels = sum(levelLines);
            levels = zeros(Nlevels,1);
            for i = 1:Nlevels
                levels(i) = sscanf(levelsTxt(i), 'Level=%ddB');
            end
        end
        
        function [durations, Ndurations] = get_Durations(fileData)
            % Get lines indicating Levels
            durationLines = ~cellfun(@isempty, regexp(fileData, 'Aqu. Duration:'));
            durationTxt = strrep(fileData(durationLines), ' ', '');
            
            Ndurations = sum(durationLines);
            durations = zeros(Ndurations,1);
            for i = 1:Ndurations
                durations(i) = sscanf(durationTxt(i), 'Aqu.Duration:%fms');
            end
        end
        
        function Npoints = get_Npoints(fileData)
            % Get lines indicating number of measurement points
            nbPointsLines = ~cellfun(@isempty, regexp(fileData, 'Points:'));
            nbPointsTxt = strrep(fileData(nbPointsLines), ' ', '');
            s = split(nbPointsTxt, 'No.Points:');
            Npoints = double(s(:,2));
        end 
        
%         function scaledVector = convert_Units(vector, oldScale, newScale)
%            scaledVector = vector * oldScale/newScale; 
%         end
    end
end