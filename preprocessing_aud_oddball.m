%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG - Vorverarbeitung
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dieses Skript kann zur Vorverarbeitung von EEG-Daten verwendet werden. 
% Die Pfade und Verarbeitungsschritte müssen an die Ordnerstruktur und die
% Daten angepasst werden.

% um mit einer frischen Matlab-Umgebung zu starten
clear all

% zunaechst: EEGLAB als Toolbox-Pfad definieren
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% General Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zunaechst muessen alle Pfade definiert werden, damit MATLAB weiß wo es
% die Funktionen und Daten findet.

%% Directory definieren
DIR = 'A:\Hamm\Department Hamm 2\IWP Unterlagen\11_Wirtschaftspsychologisches Labor\EEG\Experimente\Oddball\test'
SUB = {'1', '2'}; %, '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40'};    
BDFFILE = 'A:\Hamm\Department Hamm 2\IWP Unterlagen\11_Wirtschaftspsychologisches Labor\EEG\Experimente\Oddball\test\BDF.txt'
CHANNELDIR = 'A:\Hamm\Department Hamm 2\IWP Unterlagen\11_Wirtschaftspsychologisches Labor\EEG\Experimente\Oddball\test\electrode_positions_16channel.sfp'
% Der Pfad wo die Datei mit den Interpolierten Elektroden liegt
INTERDIR = 'A:\Hamm\Department Hamm 2\IWP Unterlagen\11_Wirtschaftspsychologisches Labor\EEG\Experimente\Oddball\test'



%% Wird für die Interpolation benoetigt
[ndata1, text1, alldata1] = xlsread([INTERDIR filesep 'Interpolated_Channels']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Start der Vorverarbeitung - Loop für alle VPs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Loop through each subject listed in SUB
for i = 1:length(SUB)

    %% Definition des Vollständigen file-paths zum einlesen
    filepath = fullfile(DIR, SUB{i});
    filename = [SUB{i}, '_oddball.xdf'];
    fullFileName = fullfile(filepath, filename);
    
    %% Dataset der Vpn in MatLab einlesen
    % je nachdem ob die Daten als .xdf oder .set vorliegen entsprechend die
    % einlese Funktion auswählen
    
    %% .set-file einlesen
    % EEG = pop_loadset('filename',[SUB{i} '_oddball.set'],'filepath', [DIR filesep SUB{i}]);
    
    %% .xdf-file einlesen
    % EEG = pop_loadxdf('filename',[SUB{i} '_oddball.xdf'] ,'filepath', [DIR filesep SUB{i}]);
    EEG = pop_loadxdf(fullFileName)
    % EEG = pop_loadxdf('A:\Hamm\Department Hamm 2\IWP Unterlagen\11_Wirtschaftspsychologisches Labor\EEG\Experimente\Oddball\test\1\1_oddball.xdf' , 'streamname', 'obci_eeg1', 'streamtype', 'EEG', 'exclude_markerstreams', {});
    
    % EEG-Datensatz speichern
    EEG = eeg_checkset( EEG ); %EEG-Checkset: checkt Konsistenz der Felder eines EEG-Datensatzes 
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    %% Re-Sampling: 125 Hz
    
    EEG = pop_resample( EEG, 125); % gegebenenfalls die sampling-rate anpassen
    %Speichern in neuem Dataset
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[SUB{i} '_oddball_125Hz'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz'],'gui','off'); 
    
    EEG = eeg_checkset( EEG );

    %% Re-Referencing: average referencing
    
    EEG = pop_reref( EEG, [] );
    %Speichern in neuem Dataset
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[SUB{i} '_oddball_125Hz_av'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av'],'gui','off'); 
    
    
    %% Filter: FIR, Highpass 0.1 Lowpass 20
        
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',0);
    EEG = pop_eegfiltnew(EEG, 'hicutoff',20,'plotfreqz',0);
    % Speichern in neuem Dataset
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname',[SUB{i} '_oddball_125Hz_av_FIR'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR'],'gui','off'); 
    EEG = eeg_checkset( EEG );
    
    %% Kanäle einlesen anhand von .elp-Datei oder .sfp-Datei 
    EEG=pop_chanedit(EEG, 'load', CHANNELDIR);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    %% Interpolation

    EEG = pop_interp(EEG, [10], 'spherical');
    % Speichern in neuem Dataset
    ignored_channels = [29 30 31];  % wenn z.b. Augenelektroden mit aufgezeichent wurden      
    DimensionsOfFile1 = size(alldata1);
    for j = 1:DimensionsOfFile1(1);
        if isequal(SUB{i},num2str(alldata1{j,1}));
           badchans = (alldata1{j,2});
           if ~isequal(badchans,'none') | ~isempty(badchans)
       	      if ~isnumeric(badchans)
                 badchans = str2num(badchans);
              end
              EEG  = pop_erplabInterpolateElectrodes( EEG , 'displayEEG',  0, 'ignoreChannels',  ignored_channels, 'interpolationMethod', 'spherical', 'replaceChannels', badchans);
           end
           [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[SUB{i} '_oddball_125Hz_av_FIR_interpol'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR_interpol'],'gui','off');
        end
    end
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4, 'setname', [SUB{i} '_oddball_125Hz_av_FIR_interpol'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR_interpol'],'gui','off');


    %% Epochierung und Baseline-Korrektur
    %% Event-List kreieren
    EVENTFILE = [DIR filesep SUB{i} filesep 'events_' SUB{i} '.txt']
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist', EVENTFILE ); 

    % Event-List speichern

    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR_interpol_elist'],'gui','off'); 

    pop_squeezevents(EEG);

    %% Bin-Lister einlesen
    BINLISTER = [[DIR filesep SUB{i}] filesep SUB{i} '_AssignBins.txt']
    EEG  = pop_binlister( EEG , 'BDF', BDFFILE, 'ExportEL', BINLISTER, 'IndexEL',  1, 'SendEL2', 'EEG&Text', 'Voutput', 'EEG' ); 
    
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %% Epochierung: -200, 1.000
    EEG = pop_epochbin( EEG , [-200.0  1000.0],  'pre');
    % Neues Dataset speichern
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname',[SUB{i} '_oddball_125Hz_av_FIR_interpol_elist_binsas_epoch'],'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR_interpol_elist_binsas_epoch'],'gui','off'); 
    EEG = eeg_checkset( EEG );
    
    %% Artefakte detektieren: alles über -100 / 100
    EEG  = pop_artextval( EEG , 'Channel',  1:16, 'Flag',  1, 'LowPass',  -1, 'Threshold', [ -150 150], 'Twindow', [ -199.2 996.1] ); 
    % Neues Dataset speichern
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'savenew',[DIR filesep SUB{i} filesep SUB{i} '_oddball_125Hz_av_FIR_interpol_elist_binsas_epoch_ar'],'gui','off'); 
    
    EEG = pop_summary_AR_eeg_detection(EEG, [SUB{i} '_oddball_125Hz_av_FIR_interpol_elist_binsas_epoch_ar']); 
    
    %% ERP-Funktionen
   
    ERP = pop_averager( ALLEEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'DSindex', 9, 'ExcludeBoundary', 'on', 'SEM', 'on' );
    
    ERP = pop_savemyerp(ERP, 'erpname', [SUB{i} '_oddball_ERP'], 'filename', [SUB{i} '_oddball_ERP.erp'], 'filepath', [DIR filesep SUB{i}], 'Warning', 'on');
 
    % Calculate the percentage of trials that were rejected in each bin 
    accepted = ERP.ntrials.accepted;
    rejected= ERP.ntrials.rejected;
    percent_rejected= rejected./(accepted + rejected)*100;
    
    % Calculate the total percentage of trials rejected across all trial types (first two bins)
    total_accepted = accepted(1) + accepted(2);
    total_rejected= rejected(1)+ rejected(2);
    total_percent_rejected= total_rejected./(total_accepted + total_rejected)*100; 
    
    % Save the percentage of trials rejected (in total and per bin) to a .csv file 
    fid = fopen([DIR filesep SUB{i} filesep SUB{i} '_AR_Percentages_oddball.csv'], 'w');
    % fid = fopen([DIR filesep SUB{i} filesep SUB{i} '_AR_Percentages_N2pc.csv'], 'w');
    fprintf(fid, 'SubID,Bin,Accepted,Rejected,Total Percent Rejected\n');
    fprintf(fid, '%s,%s,%d,%d,%.2f\n', SUB{i}, 'Total', total_accepted, total_rejected, total_percent_rejected);
    bins = strrep(ERP.bindescr,', ',' - ');
    for b = 1:length(bins)
        fprintf(fid, ',%s,%d,%d,%.2f\n', bins{b}, accepted(b), rejected(b), percent_rejected(b));
    end
    fclose(fid);

%% end loop
end