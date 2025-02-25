clear;
gridType='EEG'; 
folderSourceString='C:\Users\srivi\Desktop\updated_codes281021';
folderOutString='C:\Users\srivi\Desktop\updated_codes281021';

[subjectNames,expDates,protocolNames,stimTypes,deviceNames,capLayouts] = allProtocolsOBCIGammaProject;
electrodeLabels = ["O1","O2","T5","P3","Pz","P4","T6","Ref"];
extractTheseIndices = 1:68; % choose the protocol numbers you want to extract from allProtocolsOBCIGammaProject;
Fsampling = 250; % sampling frequency
for iProt = 1:length(extractTheseIndices)
    
    subjectName = subjectNames{extractTheseIndices(iProt)};
    expDate= expDates{extractTheseIndices(iProt)};
    protocolName= protocolNames{extractTheseIndices(iProt)};
    deviceName = deviceNames{extractTheseIndices(iProt)};
    capLayout = capLayouts{extractTheseIndices(iProt)};
    
    %% Eye open and eye closed data for OpenBCI
    clear eegData
    if strcmpi(protocolName,'GRF_001') || strcmpi(protocolName,'GRF_002')
        Fs = Fsampling;
        fileName = [subjectName expDate protocolName];
        folderName = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName);
        makeDirectory(folderName);
        folderIn = fullfile(folderSourceString,'data','rawData',[subjectName expDate]);
        folderExtract = fullfile(folderName,'extractedData');
        makeDirectory(folderExtract);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % use readtable MATLAB function to read the code
        eegData = readtable(fullfile(folderIn, fileName), 'HeaderLines', 4, 'ReadVariableNames', 1);
        
        analogInputNums = 1:8;
        disp(['Total number of Analog channels recorded: ' num2str(length(analogInputNums))]);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%% EEG Decomposition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        analysisTimeToBeUsed = 60; % in seconds
        analysisOnsetTimes = 3:1:analysisTimeToBeUsed-1; %goodStimTimes + timeStartFromBaseLine; 
        %starting from 3rd second to remove starting artefacts from
        %recording
        times = 0.004 * (1:height(eegData)); % This is in seconds
        deltaT = 1.000; % in seconds;
        
        if (~isempty(analogInputNums))
            
            % Set appropriate time Range
            numSamples = deltaT*Fs;
            timeVals = (1/Fs:1/Fs:deltaT);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Prepare folders
            folderOut = fullfile(folderName,'segmentedData');
            makeDirectory(folderOut); % main directory to store EEG Data
            
            % Make Diectory for storing LFP data
            outputFolder = fullfile(folderOut,'LFP'); % Still kept in the folder LFP to be compatible with Blackrock data
            makeDirectory(outputFolder);
            
            % Now segment and store data in the outputFolder directory
            totalStim = length(analysisOnsetTimes);
            goodStimPos = zeros(1,totalStim);
            for i=1:totalStim
                goodStimPos(i) = find(times>analysisOnsetTimes(i),1);
            end
            
            for i=1:8
                disp(['elec' num2str(analogInputNums(i))]);
                
                clear analogData
                analogData = zeros(totalStim,numSamples);
                for j=1:totalStim
                    analogData(j,:) = eegData{goodStimPos(j)+1:goodStimPos(j)+numSamples,i+1};
                end
                analogInfo = struct('label', electrodeLabels(i)); 
                save(fullfile(outputFolder,['elec' num2str(analogInputNums(i)) '.mat']),'analogData','analogInfo');
            end
            
            % Write LFP information. For backward compatibility, we also save
            % analogChannelsStored which is the list of electrode data
            electrodesStored = analogInputNums;
            analogChannelsStored = electrodesStored;
            save(fullfile(outputFolder,'lfpInfo.mat'),'analogChannelsStored','electrodesStored','analogInputNums','goodStimPos','timeVals');
        end

    end
    
    %% Eye open and eye closed for BrainProducts
    
    if strcmpi(protocolName,'GRF_004') || strcmpi(protocolName,'GRF_005')
        fileName = [subjectName expDate protocolName '.vhdr'];
        folderName = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName);
        makeDirectory(folderName);
        folderIn = fullfile(folderSourceString,'data','rawData',[subjectName expDate]);
        folderExtract = fullfile(folderName,'extractedData');
        makeDirectory(folderExtract);
        
        % Following code is adapted from 
        % github.com/supratimray/CommonPrograms/blob/master/ReadData/getEEGDataBrainProducts.m
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % use EEGLAB plugin "bva-io" to read the file
        eegInfo = pop_loadbv(folderIn,fileName,[],[]);
        
        cAnalog = eegInfo.nbchan;
        Fs = eegInfo.srate;
        analogInputNums = 1:cAnalog;
        disp(['Total number of Analog channels recorded: ' num2str(cAnalog)]);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%% EEG Decomposition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        analysisTimeToBeUsed = 60; % in seconds
        analysisOnsetTimes = 0:1:analysisTimeToBeUsed-1; %goodStimTimes + timeStartFromBaseLine;
        times = eegInfo.times/1000; % This is in ms
        deltaT = 1.000; % in seconds;
        
        if (cAnalog>0)
            
            % Set appropriate time Range
            numSamples = deltaT*Fs;
            timeVals = (1/Fs:1/Fs:deltaT);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Prepare folders
            folderOut = fullfile(folderName,'segmentedData');
            makeDirectory(folderOut); % main directory to store EEG Data
            
            % Make Diectory for storing LFP data
            outputFolder = fullfile(folderOut,'LFP'); % Still kept in the folder LFP to be compatible with Blackrock data
            makeDirectory(outputFolder);
            
            % Now segment and store data in the outputFolder directory
            totalStim = length(analysisOnsetTimes);
            goodStimPos = zeros(1,totalStim);
            for i=1:totalStim
                goodStimPos(i) = find(times>analysisOnsetTimes(i),1);
            end
            
            for i=1:cAnalog
                disp(['elec' num2str(analogInputNums(i))]);
                
                clear analogData
                analogData = zeros(totalStim,numSamples);
                for j=1:totalStim
                    analogData(j,:) = eegInfo.data(analogInputNums(i),goodStimPos(j)+1:goodStimPos(j)+numSamples);
                end
                analogInfo = eegInfo.chanlocs(analogInputNums(i)); %#ok<*NASGU>
                save(fullfile(outputFolder,['elec' num2str(analogInputNums(i)) '.mat']),'analogData','analogInfo');
            end
            
            % Write LFP information. For backward compatibility, we also save
            % analogChannelsStored which is the list of electrode data
            electrodesStored = analogInputNums;
            analogChannelsStored = electrodesStored;
            save(fullfile(outputFolder,'lfpInfo.mat'),'analogChannelsStored','electrodesStored','analogInputNums','goodStimPos','timeVals');
        end

    end
    
    %% SF-ORI protocol for OpenBCI
        if strcmpi(protocolName,'GRF_003')
            % defining different segment times around stimulus onset 0.
            timeStartFromBaseLineList(1) = -0.55; deltaTList(1) = 1.024; % in seconds
            timeStartFromBaseLineList(2) = -1.148; deltaTList(2) = 2.048;
            timeStartFromBaseLineList(3) = -1.5; deltaTList(3) = 4.096;

            type = stimTypes{extractTheseIndices(iProt)};
            deltaT = deltaTList(type);
            timeStartFromBaseLine = timeStartFromBaseLineList(type);
            ML = saveMLData(subjectName,expDate,protocolName,folderSourceString,gridType);
            
            % Extract the trial error codes from the saved ML data
            folderName = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName);
            folderExtract = fullfile(folderName,'extractedData');
            trialError = load(fullfile(folderExtract,'ML.mat'), 'data');
            trialError = trialError.data;
            trialErrorCodes = zeros(1, length(trialError));
            for i=1:length(trialError)
                trialErrorCodes(i) = trialError(i).TrialError;
            end	
            % Read digital data from BrainProducts
            [digitalTimeStamps,digitalEvents]=extractDigitalDataOBCI(subjectName,expDate,protocolName,folderSourceString,gridType);

            % Compare jitter between ML times and OBCI times
            if ~isequal(ML.allCodeNumbers,digitalEvents)
                error('Digital and ML codes do not match');
            else
                disp('Digital and ML codes match!');
                clf;
                subplot(211);
                plot(1000*diff(digitalTimeStamps),'b'); hold on;
                plot(diff(ML.allCodeTimes),'r--');
                ylabel('Difference in  succesive event times (ms)');

                subplot(212);
                plot(1000*diff(digitalTimeStamps)-diff(ML.allCodeTimes));
                ylabel('Difference in ML and BP code times (ms)');
                xlabel('Event Number');

                % Stimulus Onset
                stimPos = find(digitalEvents==9);
                stimPosCorrectedTrials = stimPos(trialErrorCodes==0);
                goodStimTimes = digitalTimeStamps(stimPos+1); % digital code 9 marks start of trial, and the following digital code marks start of stimulus
                goodStimTimesCorrectedTrials = digitalTimeStamps(stimPosCorrectedTrials+1);
                stimNumbers = digitalEvents(stimPos+1);
                stimNumbersCorrectedTrials = digitalEvents(stimPosCorrectedTrials+1);
            end

%             StartPos = find(digitalEvents==9);
%             startTimes = digitalTimeStamps(StartPos);
%             EndPos = find(digitalEvents==18);
%             endTimes = digitalTimeStamps(EndPos);

%             folderStringName = fullfile(folderSourceString,'AnalysisDetails',subjectName,expDate,protocolName,'Analysis');
%             makeDirectory(folderStringName);
%             save(fullfile(folderStringName,'startTimes.mat'),'startTimes');
%             save(fullfile(folderStringName,'endTimes.mat'),'endTimes');

            folderExtract = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName,'extractedData');
            getStimResultsMLOBCI(folderExtract,stimNumbersCorrectedTrials);
            goodStimNums=1:length(stimNumbersCorrectedTrials);
            getDisplayCombinationsGRF(folderExtract,goodStimNums); % Generates parameterCombinations
            save(fullfile(folderExtract,'digitalEvents.mat'),'digitalTimeStamps','digitalEvents');

            getEEGDataOBCI(subjectName,expDate,protocolName,folderSourceString,gridType,goodStimTimesCorrectedTrials,timeStartFromBaseLine,deltaT,electrodeLabels);
            
            if iProt < 67   % no need to see bad trials in shorted electrodes
                findBadTrialsWithOBCI(subjectName,expDate,protocolName,folderSourceString,gridType,[],[],[],1,'_v5',0)
            end
        end
    
    %% SF-ORI protocol for BrainProducts
    if strcmpi(protocolName,'GRF_006')
        timeStartFromBaseLineList(1) = -0.55; deltaTList(1) = 1.024; % in seconds
        timeStartFromBaseLineList(2) = -1.148; deltaTList(2) = 2.048;
        timeStartFromBaseLineList(3) = -1.5; deltaTList(3) = 4.096;

        type = stimTypes{extractTheseIndices(iProt)};
        deltaT = deltaTList(type);
        timeStartFromBaseLine = timeStartFromBaseLineList(type);
        ML = saveMLData(subjectName,expDate,protocolName,folderSourceString,gridType);
        % Extract the trial error codes from the saved ML data
        folderName = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName);
        folderExtract = fullfile(folderName,'extractedData');
        trialError = load(fullfile(folderExtract,'ML.mat'), 'data');
        trialError = trialError.data;
        trialErrorCodes = zeros(1, length(trialError));
        for i=1:length(trialError)
            trialErrorCodes(i) = trialError(i).TrialError;
        end	
        % Read digital data from BrainProducts
        [digitalTimeStamps,digitalEvents]=extractDigitalDataBrainProducts(subjectName,expDate,protocolName,folderSourceString,gridType,5);
        % Compare ML behavior and BP files
        if ~isequal(ML.allCodeNumbers,digitalEvents)
            error('Digital and ML codes do not match');
        else
            disp('Digital and ML codes match!');
            clf;
            subplot(211);
            plot(1000*diff(digitalTimeStamps),'b'); hold on;
            plot(diff(ML.allCodeTimes),'r--');
            ylabel('Difference in  succesive event times (ms)');

            subplot(212);
            plot(1000*diff(digitalTimeStamps)-diff(ML.allCodeTimes));
            ylabel('Difference in ML and BP code times (ms)');
            xlabel('Event Number');

            % Stimulus Onset
            stimPos = find(digitalEvents==9);
            stimPosCorrectedTrials = stimPos(trialErrorCodes==0);
            goodStimTimes = digitalTimeStamps(stimPos+1);% digital code 9 marks start of trial, and the following digital code marks start of stimulus
            goodStimTimesCorrectedTrials = digitalTimeStamps(stimPosCorrectedTrials+1);
            stimNumbers = digitalEvents(stimPos+1);
            stimNumbersCorrectedTrials = digitalEvents(stimPosCorrectedTrials+1);
        end

%         StartPos = find(digitalEvents==9);
%         startTimes = digitalTimeStamps(StartPos);
%         EndPos = find(digitalEvents==18);
%         endTimes = digitalTimeStamps(EndPos);
% 
%         folderStringName = fullfile(folderSourceString,'AnalysisDetails',subjectName,expDate,protocolName,'Analysis');
%         makeDirectory(folderStringName);
%         save(fullfile(folderStringName,'startTimes.mat'),'startTimes');
%         save(fullfile(folderStringName,'endTimes.mat'),'endTimes');
        save(fullfile(folderExtract,'digitalEvents.mat'),'digitalTimeStamps','digitalEvents');

        folderExtract = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName,'extractedData');
        getStimResultsMLOBCI(folderExtract,stimNumbersCorrectedTrials);
        goodStimNums=1:length(stimNumbersCorrectedTrials);
        getDisplayCombinationsGRF(folderExtract,goodStimNums); % Generates parameterCombinations
        getEEGDataBrainProducts(subjectName,expDate,protocolName,folderSourceString,gridType,goodStimTimesCorrectedTrials,timeStartFromBaseLine,deltaT);

        if iProt < 67   % no need to see bad trials in shorted electrodes
            findBadTrialsWithOBCI(subjectName,expDate,protocolName,folderSourceString,gridType,[],[],[],1,'_v5',0)
        end
    end
    
    
end
