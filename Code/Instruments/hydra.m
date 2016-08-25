function varargout = hydra(fonction, varargin)
%   varargout = hydra(function, varargin)
%
%Function controling the HydraHarp
%
% ------------------
% (main) Functions
% -----------------
% 'initialise'          initialise the Hydra Harp device
%
% 'measure'              Measure
%   Note that none of the parameters of this function is required; they all
%   have default values.
%   Usage [x,y] = hydra('measure', param, value1, value2, ...)
%
%   One can pass multiple parameters to the function (see exemple below).
%   Parameters take zero, one or two values (see description for
%   each param below).
%
%       param
%           'c' or 'comment'
%               comment to give to experiment (string)
%                   value 1
%                       string
%           'dat' 
%               if present, create a .dat file (ascii)
%           'f' or 'filename'
%               output filename
%                   value 1
%                       string
%           'il' 
%               input trig level
%                   value 1
%                       channel (1-based)
%                   value 2
%                       trig level (mV)
%           'io' 
%               input time offset
%                   value 1
%                       channel (1-based)
%                   value 2
%                       time offset (ps)
%           'iz' 
%               input zero level
%                   value 1
%                       channel (1-based)
%                   value 2
%                       zero level (mV)
%           'r' or 'resolution'
%                   value 1
%                       resolution (ps)
%           'sd' 
%               sync divider
%                   value 1
%                       sync divider (integer)
%           'sl' 
%               sync trig level
%                   value 1
%                       trig level (mV)
%           'so' 
%               sync time offset
%                   value 1
%                       sync time offset (ps)
%           'sz' 
%               sync zero level
%                   value 1
%                       zero level (mV)
%           't' or 'accTime'
%                   value 1
%                       accumulation time (s)
%   Exemple:
%       [x,y] = hydra('measure', 'DAT', 'so', 3, 'sz',9, 'r',8 ,'il',1,599);
%       create a .dat file
%       sync offset = 3 ps
%       sync zero = 9 mV
%       resolution = 8 ps
%       input channel 1 trig level = 599 mV
%
% 'stop'                stop the HydraHarp
%
% Many other function exist, see code below.
%
% 2010
%   Nicolas
%   Code base sur le programme histomode.m de PicoQuant
% 28 avril 2011
%   Colin
%   ajouté la variable time_ns (axe temporel en ns) au fichier de sauvegarde
%30 nov 2012
%   Colin
%   Introduction d'un 'try' permettant d'utiliser cette fonction sans avoir
%   absolument besoin du picoamperemetre
% 24 avril 2015
%   Colin
%   Fonction vraiment mal ecrite. Ne devrait pas utiliser tant de variables globales
% juin 2016
%   Colin
%   Refonte complète du code, enleve les variables globales

persistent HydraHarpDevice  % represents the device
% This variable contains some state of the device. This allows to read some
% parameters that are not readable (due to the constructor library).
persistent HydraHarpState

% Constants from hhdefin.h
REQLIBVER    =      '1.2';    % this is the version this program expects
MAXDEVNUM    =          1;    % number of HydraHarp devices (control box)
MAXHISTBINS  =      65536;	 % number of histogram channels
MAXLENCODE   =          6;	 % max histogram length is 1024 * 2^MAXLENCODE
%MAXBINSTEPS	 =     	   11;   % can be read from the devise
MODE_HIST    =          0;
MODE_T2	     =          2;
MODE_T3	     =          3;

FLAG_OVERFLOW  =   hex2dec('0001');  %histo mode only
FLAG_FIFOFULL  =   hex2dec('0002');
FLAG_SYNC_LOST =   hex2dec('0004');
FLAG_REF_LOST  =   hex2dec('0008');
FLAG_SYSERROR  =   hex2dec('0010');  %hardware error, must contact support

ZCMIN		   =            0;	% mV
ZCMAX		   =           40;	% mV
DISCRMIN	   =            0;      % mV
DISCRMAX	   =         1000;      % mV
OFFSETMIN	   =            0;	% ps
OFFSETMAX	   =   1000000000;	% ps
CHANOFFSMIN    =       -99999;		% ps
CHANOFFSMAX    =        99999;		% ps
ACQTMIN		   =            1;      % ms
ACQTMAX		   =    360000000;	% ms  (100*60*60*1000ms = 100h)
STOPCNTMIN     =            1;
STOPCNTMAX     =   4294967295;          % 32 bit is mem max
SYNCDIVMAX     =           16;          % max divider for the sync input

n_arguments = -nargin(mfilename);    % number of arguments including varargin (2 here, function and varargin)
A = varargin;
N_varargin = nargin - n_arguments+1; % number of arguments in varargin
switch upper(fonction)
    case 'INITIALISE'
        HH_ERROR_DEVICE_OPEN_FAIL		 =  -1;

        fprintf('\nInitialisation of HydraHarp \n');

        if (~libisloaded('HHlib'))
            %Attention: The header file name given below is case sensitive and must
            %be spelled exactly the same as the actual name on disk except the file
            %extension.
            %Wrong case will apparently do the load successfully but you will not
            %be able to access the library!
            %The alias is used to provide a fixed spelling for any further access via
            %calllib() etc, which is also case sensitive.
            %    loadlibrary('hhlib.dll', 'hhlib.h', 'alias', 'HHlib');
            loadlibrary('hhlib.dll', 'C:\Program Files\PicoQuant\HydraHarp-HHLibv12\hhlib.h', 'alias', 'HHlib');
        end;

        if (~libisloaded('HHlib'))
            fprintf('Could not open HHlib\n');
            return;
        end;

        LibVersion = hydra('LIBRARYVERSION');
        fprintf('Library version = %s\n', LibVersion);
        if ~strcmp(LibVersion, REQLIBVER)
            fprintf('This program requires HHLib version %s\n', REQLIBVER);
            return;
        end;

        %fprintf('\nSearching for HydraHarp devices...');
        HydraHarpDevice =  [];
        found =  0;
         Serial     =  blanks(8); %enough length!
         SerialPtr  =  libpointer('cstring', Serial);
        ErrorStr   =  blanks(40); %enough length!
        ErrorPtr   =  libpointer('cstring', ErrorStr);

        for k = 0:MAXDEVNUM-1 % Initialise all HydraHarp devices
            k
            [ret, Serial] =  calllib('HHlib', 'HH_OpenDevice', k, SerialPtr);

% For some reason, this does't work
%        for k = 1:MAXDEVNUM % Initialise all HydraHarp devices
%            k
%            Serial = hydra('OpenDevice', k)
%            ret = 0;

            if (ret == 0)       % Grab any HydraHarp we successfully opened
                fprintf('S/N = %s\n', Serial);
                found =  found+1;
                HydraHarpDevice(found) = k; %keep index to devices we may want to use
            else
                if(ret == HH_ERROR_DEVICE_OPEN_FAIL)
                    fprintf('\n  %1d        no device\n', k);
                else
%                    [ret, ErrorStr] =  calllib('HHlib', 'HH_GetErrorString', ErrorPtr, ret);
                    [ret, ErrorStr] =  calllib('HHlib', 'HH_GetErrorString', ErrorPtr, ret);
                    fprintf('\n  %1d        %s\n', k, ErrorStr);
                end;
            end;
        end;
        
        % In this demo we will use the first HydraHarp device we found, i.e. HydraHarpDevice(1).
        % If you have nultiple HydraHarp devices you could also check for a specific
        % serial number, so that you always know which physical device you are talking to.

        if (found<1)
            fprintf('\nNo device available. Aborted.\n');
            return;
        end;

        % fprintf('\nUsing device #%1d', HydraHarpDevice(1));
        % fprintf('\nInitializing the device...');

        [ret] =  calllib('HHlib', 'HH_Initialize', HydraHarpDevice(1), MODE_HIST, 0);
        checkStatus(ret, 'HH_Initialize')

        % this is only for information
        [Model, Partno] = hydra('HARDWAREINFO');
        fprintf('Model = %s\n', Model);
        fprintf('Partno = %s\n', Partno);
        
        fprintf('Device has %i input channels.\n', hydra('NumInpChannels'));

        fprintf('Calibration ... \n');
        [ret] =  calllib('HHlib', 'HH_Calibrate', HydraHarpDevice(1));
        checkStatus(ret, 'HH_Calibrate')

        hydra('BASECONFIG')  % Put the device in some predefined state
        %%
    case 'BASECONFIG'
        % Put the device in some predefined state
        hydra('SYNCDIV', 8)
        hydra('SyncCFDLevel', 60)
        hydra('SyncCFDZeroCross', 10)
        hydra('SYNCCHANNELOFFSET', 0)
        hydra('InputCFDZeroCross', 1, 10)
        for i = 1:hydra('NUMINPCHANNELS')
            hydra('InputCFDZeroCross', i, 10)
            hydra('InputCFDLevel', i, 600)
            hydra('INPUTCHANNELOFFSET', i, 0)
        end
        hydra('HISTOLEN', MAXHISTBINS)
        hydra('resolution', 1)
        hydra('OFFSET', 0)
        hydra('STOPOVERFLOW', 0, 2^32-1)
        %%
    case 'TAUX'
        % Return the Sync rate and the count rate on the inputs
        SyncRate = hydra('SyncRate');
        CountRate = zeros(hydra('NUMINPCHANNELS'), 1);
        for i = 1:hydra('NUMINPCHANNELS')
            CountRate(i) = hydra('CountRate', i);
        end;

        varargout{1} = SyncRate;
        varargout{2} = CountRate;
        %%
    case 'MEASURE'
        % Measure (acquisition) the histogram of the input
        i = 1;
        % default parameters
        Comment = datestr(now); % Measure description
        Tacq = 1;  % Acquisition time (second)
        FILENAME = [datestr(now, 30) '.mat']  % output filename
                                              % (current date and time)
        create_dat_file = 0;

        while i <= N_varargin
            switch upper(A{i})
                case {'C', 'COMMENT'}
                    % Measure description (string)
                    Comment = A{i+1};
                    i = i + 2;
                case 'DAT'
                    create_dat_file = 1
                    i = i+1;
                case {'F', 'FILENAME'}
                    FILENAME = A{i+1};  % output filename (in .mat format)
                    i = i + 2;
                case 'IL'  % input trig level
                    % parameter 1
                    %    channel (1-based)
                    % parameter 2
                    %    trig level (mV)
                    hydra('INPUTCFDLEVEL', A{i+1}, A{i+2});
                    i = i + 3;
                case 'IO'  % input time offset
                    % parameter 1
                    %    channel (1-based)
                    % parameter 2
                    %    time offset (ps)
                    hydra('INPUTCHANNELOFFSET', A{i+1}, A{i+2});
                    i = i + 3;
                case 'IZ'  % input zero level
                    % parameter 1
                    %    channel (1-based)
                    % parameter 2
                    %    zero level (mV)
                    hydra('INPUTCFDZEROCROSS', A{i+1}, A{i+2});
                    i = i + 3;
                case {'R', 'RESOLUTION'}  % resolution (ps)
                    hydra('resolution', A{i+1});
                    i = i + 2;
                case 'SD'  % sync divider
                    hydra('SYNCDIV', A{i+1});
                    i = i + 2;
                case 'SL'  % sync trig level (mV)
                    hydra('SYNCCFDLEVEL', A{i+1});
                    i = i + 2;
                case 'SO'  % sync time offset (pS)
                    hydra('SYNCCHANNELOFFSET', A{i+1});
                    i = i + 2;
                case 'SZ'  % sync zero level (mV)
                    hydra('SYNCCFDZEROCROSS', A{i+1});
                    i = i + 2;
                case {'T', 'ACCTIME'}  % acquisition time (second)
                    Tacq = A{i+1};
                    i = i + 2;
                otherwise
                    % Mauvais parametre
                    i = i + 1;
                    fprintf('\n mauvais parametre\n')
            end
        end

        % !!! This is variable is related to the picoamperemetre
        % for me this is a realy bad practice. Should be moved out
        %         %variable globale lie au graphique du picoamperemetre
        global hs

        Resolution = hydra('resolution')
        fprintf('\nResolution = %1dps', Resolution);

        SyncRate = hydra('SyncRate')  % Count rate for the sync input
        CountRate = zeros(hydra('NUMINPCHANNELS'), 1);  % Count
                                                        % rate for
                                                        % the inputs
        fprintf('\nSyncRate = %1d/s ', SyncRate);
        for i = 1:hydra('NUMINPCHANNELS')
            CountRate(i+1) = hydra('CountRate', i)
            fprintf('\nCountRate%1d = %1d/s ', i, CountRate(i+1));
        end;

        disp(hydra('WARNINGSTEXT'))
        % One MUST call hydra('SyncRate') and hydra('CountRate', i)
        % for all channels BEFORE to call hydra('WARNINGSTEXT')

        % Delete histogram from device
        hydra('CLEARHISTMEM')

        % start measurement on the device
        hydra('STARTMEAS', Tacq)

        fprintf('\nMesure pour %1d seconde(s)...', Tacq);

        %Initialisation de l'interface graphique, fait par trivista_hydra, à ne pas
        %mettre en commentaire si l'on utilise la fonction hydra_mesure seule
        %    clf, figure(1)
        %    hs = uicontrol('style', 'radiobutton', 'string', 'stop');

        %On effectue le mesure et on lit le picoamperemetre en meme temps et on
        %l'affiche.
        % ctcdone =  int32(0);
        % ctcdonePtr =  libpointer('int32Ptr', ctcdone);
        ctcdone =  0;
        courant = [];  % This should be put out of hydra.m
        t =  clock;
        % Contains counting rates during the measurement
        totSR = [];
        totCR = [];
        time_laboratory = [];  % Real time (wall clock) spent for measurement
        %%
        % !!! Cette boucle est batarde! C'est con de mettre pico6485 ici!
        % C'est aussi con d'ouvrir une figure.
        % Should be done in another loop outside of the HydraHarp function
        while (ctcdone == 0)
            %     [ret, ctcdone] =  calllib('HHlib', 'HH_CTCStatus', HydraHarpDevice(1), ctcdonePtr);
            ctcdone = hydra('CTCSTATUS');
            try
                courant =  [courant;abs(pico6485('lecture'))] ;
                figure(21)
                h1 = plot(courant, '-');axis([0 inf 0 max(courant)*1.1]); %Graphique du courant
            end
            %title(['reste encore ' num2str(round(Tacq-etime(clock, t))) ' s a la mesure de lambda = ' num2str(lam) 'nm'])
            title(['reste encore ' num2str(round(Tacq-etime(clock, t))) ' s a la mesure'])
            %     [SR, CR1, CR2] = hydra_taux_comptage(arg);
            [SR, CR] = hydra('taux');

            time_laboratory = [time_laboratory round(etime(clock, t))];
            totCR = [totCR CR];
            totSR = [totSR SR];
            texte = sprintf('SyncRate = %3.2e/s \n', SR);
            texte = [texte sprintf('CountRate = %3.2e/s \n', CR)];
            xlabel(texte);
            stop = get(hs, 'value');%On regarde si le bouton stop a été coche pour arreter la mesure
            if stop == 1
                break
            end
            drawnow
            pause(1)
        end;

        % Stop measurement 
        hydra('STOPMEAS')

        % !!! Sould be improved
        % Boiteux: MAXHISTBINS
        % On devrait connaitre le nombre exact de pixels valides avant la mesure
        %
        % L'histogramme de chaque cannaux est conservé dans une ligne de la variable countsbuffer
        countsbuffer =  uint32(zeros(hydra('NUMINPCHANNELS'), MAXHISTBINS));
        for i = 1:hydra('NUMINPCHANNELS')
            countsbuffer(i, :) = hydra('HISTOGRAM', i, 1);
        end;

        % Boiteux: maxIndex et max(find(countsbuffer(i, :)>0))
        % On devrait connaitre le nombre exact de pixels valides avant la mesure
        %
        %nettoye les donnees. Enleve les zeros
        maxIndex = length(countsbuffer);  % contient l'indice du dernier element non nul
        for i =  [1:size(countsbuffer, 1)]
            a =  max(find(countsbuffer(i, :)>0));
            if ~isempty(a)
                if a < maxIndex
                    maxIndex =  a;
                end
            end
        end

        % Get the flags
        hydra('flagstext')

        Integralcount =  sum(countsbuffer'); % Total counts for
                                             % each channel

        %On affiche les donnes relatives au nombre de compte de la mesure
        count_constante = [];

        % !!!
        % mettre ca dans une boucle 1:hydra('NUMINPCHANNELS')
        %
        fprintf('\nTotalCount_Ch1 = %1d', Integralcount(1));
        if min(double(totSR(2:end)))>0
            Max_Count_Rate_Ch1 = max(double(totCR(2:end,1))./double(totSR(2:end)));
            Avg_Count_Rate_Ch1 = sum(double(totCR(2:end),1)./double(totSR(2:end)))/length(double(totSR(2:end)));
            Min_Count_Rate_Ch1 = min(double(totCR(2:end),1)./double(totSR(2:end)));

            fprintf('\nMax_Count_Rate_Ch1 = %6.4f \nAverage_Count_Rate_Ch1 = %6.4f \nMin_Count_Rate_Ch1 = %6.4f', Max_Count_Rate_Ch1, Avg_Count_Rate_Ch1, Min_Count_Rate_Ch1)
        else
            fprintf('\n Le taux de comptage de la reference a atteind zero lors de la mesure')
        end

        fprintf('\n');

        fprintf('\nTotalCount_Ch2 = %1d', Integralcount(2));%%; (si fct utilisée seule)
        if min(double(totSR(2:end)))>0
            Max_Count_Rate_Ch2 = max(double(totCR(2:end),2)./double(totSR(2:end)));
            Avg_Count_Rate_Ch2 = sum(double(totCR(2:end),2)./double(totSR(2:end)))/length(double(totSR(2:end)));
            Min_Count_Rate_Ch2 = min(double(totCR(2:end),2)./double(totSR(2:end)));

            fprintf('\nMax_Count_Rate_Ch2 = %6.4f \nAverage_Count_Rate_Ch2 = %6.4f \nMin_Count_Rate_Ch2 = %6.4f', Max_Count_Rate_Ch2, Avg_Count_Rate_Ch2, Min_Count_Rate_Ch2)
        else
            fprintf('\n Le taux de comptage de la reference a atteind zero lors de la mesure')
        end
        fprintf('\n');

        Binning = binning(hydra('resolution'));

        fprintf('\nSauve file...\n');
        time_ns = (0:1:65535)*Resolution/1000;

        % For saving data in ascii format
        if create_dat_file == 1
            filename_dat = strrep(FILENAME, '.mat', '.dat'); % .mat -> .dat
            fid =  fopen(filename_dat, 'w');
            if (fid<0)
                fprintf('Cannot open output file\n');
                return;
            end;

            fprintf(fid, ['Comment                   : ' Comment '\n']);
%            fprintf(fid, 'Binning              : %ld\n', Binning);
            fprintf(fid, 'Resolution           (ps) : %ld\n', Resolution);
            fprintf(fid, 'AcquisitionTime      (s)  : %ld\n', Tacq);
            fprintf(fid, 'SyncDivider              : %ld\n', hydra('SYNCDIV'));
            fprintf(fid, 'SyncCFDZeroCross     (mV) : %ld\n', hydra('SYNCCFDZEROCROSS'));
            fprintf(fid, 'SyncCFDLevel         (mV) : %ld\n', hydra('SYNCCFDLEVEL'));
            fprintf(fid, 'SYNCCHANNELOFFSET    (ps) : %ld\n', hydra('SYNCCHANNELOFFSET'));
            for j = 1:hydra('NUMINPCHANNELS')
                fprintf(fid, 'InputCFDZeroCross %d  (mV) : %ld\n', j, hydra('INPUTCFDZEROCROSS',j));
                fprintf(fid, 'InputCFDLevel %d      (mV) : %ld\n', j, hydra('INPUTCFDLEVEL',j));
                fprintf(fid, 'INPUTCHANNELOFFSET %d  (ps) : %ld\n', j, hydra('INPUTCHANNELOFFSET',j));
            end
            fprintf(fid, 'Time(ns) CountCh1  CountCh2\n ');
            for i = 1:MAXHISTBINS
                fprintf(fid, '%7d %7d ', time_ns(i), countsbuffer(:, i));
                fprintf(fid, '\n');
            end;

            fprintf(fid, 'Current');
            for i = 1:length(courant)
                fprintf(fid, '%7d ', courant(i));
                fprintf(fid, '\n');
            end;
            fprintf('\nData saved in %s \n', filename_dat);
            if(fid>0)
                fclose(fid);
            end
        end

        % !! batard
        % Keep non nul data
        time_ns =  time_ns(1:maxIndex);
        countsbuffer =  countsbuffer(:, 1:maxIndex);

        % Print graphics
        figure(22)
        semilogy(time_ns, countsbuffer', '.')
        xlabel('Time (ns)')

        CountRate_laboratoire = totCR;
        SyncRate_laboratoire = totSR;

        % save in .mat
        save(FILENAME, 'countsbuffer', 'courant', 'CountRate_laboratoire', 'SyncRate_laboratoire', 'Binning', 'Resolution', 'Tacq', 'HydraHarpState', 'time_ns', 'Comment', 'time_laboratory')

        fprintf('\nLes donnees sont enregistrees dans %s \n', FILENAME);

        varargout{1} = time_ns;
        varargout{2} = countsbuffer;
    case 'STOP'
        % close device
        fprintf('\nclosing all HydraHarp devices\n');
        if (libisloaded('HHlib'))
            for(i = 0:7); % no harm to close all
                calllib('HHlib', 'HH_CloseDevice', i);
            end;
        end
        %%
        %% Following are internal functions (user should not have to use them)
        %%
    case 'BASERESOLUTION'
        % base resolution (ps) and MAXBINSTEP
        stringPre = 'HH_Get';
        stringLib = 'BaseResolution';
        if N_varargin < 1  % read
            out =  0;
            outPtr =  libpointer('doublePtr', out);
            out2 =  0;
            outPtr2 =  libpointer('int32Ptr', out2);
            [ret, out, out2] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr, outPtr2);
            checkStatus(ret, [stringPre stringLib])
            varargout{1} = out;
            varargout{2} = out2;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'CLEARHISTMEM'
        % clear the histogram
        stringPre = 'HH_';
        stringLib = 'ClearHistMem';
        [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1));
        checkStatus(ret, [stringPre stringLib])
    case 'COUNTRATE'
        % count rate on inputs
        % parameter
        %   input channel (1-based)
        stringPre = 'HH_Get';
        stringLib = 'CountRate';
        if N_varargin < 2  % read
            channel = varargin{1} - 1;  % 1 based -> 0-based
            channel = setInRange(channel, 0, hydra('NUMINPCHANNELS')-1);
            out =  0;
            outPtr =  libpointer('int32Ptr', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), channel, outPtr);
            checkStatus(ret, [stringPre stringLib])
            varargout{1} = out;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'CTCSTATUS'
        % status of acquisition
        % output
        %   0 = acquisition time still running
        %   1 = acquisition time has ended
        stringPre = 'HH_';
        stringLib = 'CTCStatus';
        out =  int32(0);
        outPtr =  libpointer('int32Ptr', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;
    case 'ERRORSTRING'
        % current status flags (a bit pattern)
        stringPre = 'HH_Get';
        stringLib = 'ErrorString';
        in = varargin{1};  % error code
        out =  blanks(40);
        outPtr =  libpointer('cstring', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], outPtr, in);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;               
    case 'FLAGS'
        % current status flags (a bit pattern)
        stringPre = 'HH_Get';
        stringLib = 'Flags';
        out =  int32(0);
        outPtr =  libpointer('int32Ptr', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;
    case 'FLAGSTEXT'
        % current status flags (text)
        out = [];
        flags = hydra('FLAGS');
        if(bitand(uint32(flags), FLAG_OVERFLOW))
            out = strvcat(out,'Overflow')
        end;
        if(bitand(uint32(flags), FLAG_SYNC_LOST))
            out = strvcat(out,'FIFOFULL')
        end;
        if(bitand(uint32(flags), FLAG_REF_LOST))
            out = strvcat(out,'SYNC_LOST')
        end;
        if(bitand(uint32(flags), FLAG_SYSERROR))
            out = strvcat(out,'SYSERROR')
        end;
        varargout{1} = out;
    case 'HARDWAREINFO'
        % model and part number
        stringPre = 'HH_Get';
        stringLib = 'HardwareInfo';
        Model       =  blanks(16); %enough length!
        Partno      =  blanks(8); %enough length!
        ModelPtr    =  libpointer('cstring', Model);
        PartnoPtr   =  libpointer('cstring', Partno);
        [ret, Model, Partno] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), ModelPtr, PartnoPtr);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = Model;
        varargout{2} = Partno;
    case 'HISTOGRAM'
        % get histogram from the device
        % parameter 1
        %   input channel (1-based)
        % parameter 2
        %   0 = keeps the histogram in the acquisition buffe
        %   1 = clears the acquisition buffer
        stringPre = 'HH_Get';
        stringLib = 'Histogram';
        channel = varargin{1} - 1;  % 1-based -> 0-based
        clearBuffer = varargin{2};
        in1 = setInRange(channel, 0, hydra('NUMINPCHANNELS')-1);
        in2 = setInRange(clearBuffer, 0, 1);
        out =  uint32(zeros(1, MAXHISTBINS));
        outPtr =  libpointer('uint32Ptr', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr, in1, in2);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;
    case 'HISTOLEN'
        % histogram length (power of 2. Minimum 1024, Maximum MAXHISTBINS=65536)
        stringPre = 'HH_Set';
        stringLib = 'HistoLen';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.HISTOLEN;
        else  % set
            in = varargin{1};
            out =  0;
            outPtr =  libpointer('int32Ptr', out);
            in = round(log2(in/1024));
            in = setInRange(in, 0, MAXLENCODE);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in, out);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.HISTOLEN = out;
            %varargout{1} = out;
        end
    case 'INPUTCFDLEVEL'
        % input threshold level (mV)
        stringPre = 'HH_Set';
        stringLib = 'InputCFDLevel';
        if N_varargin < 2  % read
            channel = varargin{1} - 1;  % 1 based
            varargout{1} = HydraHarpState.INPUTCFDLEVEL(channel+1);
        else  % set
            channel = varargin{1} - 1;  % 1 based
            in = varargin{2};
            channel = setInRange(channel, 0, hydra('NUMINPCHANNELS')-1);
            in = setInRange(in, DISCRMIN, DISCRMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), channel, in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.INPUTCFDLEVEL(channel+1) = in;
        end
    case 'INPUTCFDZEROCROSS'
        % input zero level (mV)
        stringPre = 'HH_Set';
        stringLib = 'InputCFDZeroCross';
        if N_varargin < 2  % read
            channel = varargin{1} - 1;  % 1 based
            varargout{1} = HydraHarpState.INPUTCFDZEROCROSS(channel+1);
        else  % set
            channel = varargin{1} - 1;  % 1 based
            in = varargin{2};
            MAX = hydra('NUMINPCHANNELS')-1;
            channel = setInRange(channel, 0, MAX);
            in = setInRange(in, ZCMIN, ZCMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), channel, in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.INPUTCFDZEROCROSS(channel+1) = in;
        end
    case 'INPUTCHANNELOFFSET'
        % input temporal shift (ps)
        % parameter 1
        %   input channel (1-based)
        % parameter 2
        %   temporal shift (ps)
        stringPre = 'HH_Set';
        stringLib = 'InputChannelOffset';
        if N_varargin < 2  % read
            channel = varargin{1} - 1;  % 1 based -> 0-based
            varargout{1} = HydraHarpState.INPUTCHANNELOFFSET(channel+1);
        else  % set
            channel = varargin{1} - 1;  % 1 based -> 0-based
            in = varargin{2};
            in = setInRange(in, CHANOFFSMIN, CHANOFFSMAX);
            channel = setInRange(channel, 0, hydra('NUMINPCHANNELS')-1);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), channel, in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.INPUTCHANNELOFFSET(channel+1) = in;
        end
    case 'LIBRARYVERSION'
        % number of installed input channel
        stringPre = 'HH_Get';
        stringLib = 'LibraryVersion';
        if N_varargin < 1  % read
            out =  blanks(8);
            outPtr =  libpointer('cstring', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], outPtr);
            checkStatus(ret, [stringPre stringLib])
            
            varargout{1} = out;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'NUMINPCHANNELS'
        % number of installed input channel
        stringPre = 'HH_Get';
        stringLib = 'NumOfInputChannels';
        if N_varargin < 1  % read
            out =  0;
            outPtr =  libpointer('int32Ptr', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
            checkStatus(ret, [stringPre stringLib])
            varargout{1} = out;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'OFFSET'
        % time offset (ps)
        % maximum seams to be 500000
        stringPre = 'HH_Set';
        stringLib = 'Offset';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.OFFSET;
        else  % set
            in = varargin{1};
            in = setInRange(in, OFFSETMIN, OFFSETMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.OFFSET = in;
        end
    case 'LIBRARYVERSION'
        % number of installed input channel
        stringPre = 'HH_Get';
        stringLib = 'LibraryVersion';
        if N_varargin < 1  % read
            out =  blanks(8);
            outPtr =  libpointer('cstring', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], outPtr);
            checkStatus(ret, [stringPre stringLib])
            
            varargout{1} = out;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'OPENDEVICE'
        % number of installed input channel
        stringPre = 'HH_';
        stringLib = 'OpenDevice';
        if N_varargin < 1  % read
            fprintf('Must give a device number.\n');
        else  % set
            in = varargin{1} - 1  % 1-based -> 0-based
            out =  blanks(8);
            outPtr =  libpointer('cstring', out);
                         %calllib('HHlib', 'HH_OpenDevice', k, SerialPtr);
            %[ret, out] =  calllib('HHlib', [stringPre stringLib], in, outPtr)
            [ret, out] =  calllib('HHlib', 'HH_OpenDevice', 0, outPtr)
            checkStatus(ret, [stringPre stringLib])   
            varargout{1} = out;
        end                  
    case 'RESOLUTION'
        % temporal resolution of device (ps)
        % parameter
        %   resolution 1 - 1024 ps. power of 2
        stringPre = 'HH_Get';
        stringLib = 'Resolution';
        stringPreSet = 'HH_Set';
        stringLibSet = 'Binning';
        if N_varargin < 1  % read
            out =  0;
            outPtr =  libpointer('doublePtr', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
            checkStatus(ret, [stringPre stringLib])
            varargout{1} = out;
        else  % set
            [baseResolution, MAXBINSTEPS] = hydra('BASERESOLUTION');
            in = varargin{1}
            in = binning(in)
            in = setInRange(in, 0, MAXBINSTEPS-1);
            [ret] =  calllib('HHlib', [stringPreSet stringLibSet], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPreSet stringLibSet])
            %varargout{1} = hydra('resolution');
        end
    case 'STARTMEAS'
        % start acquisition
        % parametre
        %   acquisition time (second)
        stringPre = 'HH_';
        stringLib = 'StartMeas';
        Tacq = round(varargin{1}*1000);  % acquisition time (second)
        in = setInRange(Tacq, ACQTMIN, ACQTMAX);
        [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
        checkStatus(ret, [stringPre stringLib])
    case 'STOPMEAS'
        % stop Acquisition
        stringPre = 'HH_';
        stringLib = 'StopMeas';
        [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1));
        checkStatus(ret, [stringPre stringLib])
    case 'STOPOVERFLOW'
        stringPre = 'HH_Set';
        % stop overflow
        % parameter 1
        %   0 do not stop on overflow
        %   1 stop on overflow
        % parameter 2
        %   count level at which should be stopped
        stringLib = 'StopOverflow';
        if N_varargin < 1  % read
            fprintf('\nNot implemented. \n');
        else  % set
            stop_ovfl = varargin{1};
            stopcount = varargin{2};
            in = setInRange(stop_ovfl, 0, 1);
            in2 = setInRange(stopcount, STOPCNTMIN, STOPCNTMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in, in2);
            checkStatus(ret, [stringPre stringLib])
        end
    case 'SYNCCFDLEVEL'
        % sync threshold level (mV)
        stringPre = 'HH_Set';
        stringLib = 'SyncCFDLevel';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.SYNCCFDLEVEL;
        else  % set
            in = varargin{1};
            in = setInRange(in, DISCRMIN, DISCRMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.SYNCCFDLEVEL = in;
        end
    case 'SYNCCFDZEROCROSS'
        % sync zero level (mV)
        stringPre = 'HH_Set';
        stringLib = 'SyncCFDZeroCross';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.SYNCCFDZEROCROSS;
        else  % set
            in = varargin{1};
            in = setInRange(in, ZCMIN, ZCMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.SYNCCFDZEROCROSS = in;
        end
    case 'SYNCCHANNELOFFSET'
        % sync temporal shift (ps)
        stringPre = 'HH_Set';
        stringLib = 'SyncChannelOffset';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.SYNCCHANNELOFFSET;
        else  % set
            in = varargin{1};
            in = setInRange(in, CHANOFFSMIN, CHANOFFSMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.SYNCCHANNELOFFSET = in;
        end
    case 'SYNCDIV'
        % sync divisor (power of 2)
        stringPre = 'HH_Set';
        stringLib = 'SyncDiv';
        if N_varargin < 1  % read
            varargout{1} = HydraHarpState.SYNCDIV;
        else  % set
            in = varargin{1};
            in = 2^round(log2(in)); % power of 2
            in = setInRange(in, 1, SYNCDIVMAX);
            [ret] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), in);
            checkStatus(ret, [stringPre stringLib])
            HydraHarpState.SYNCDIV = in;
        end
        pause(0.4);% after Init or SetSyncDiv you must allow 400 ms for valid new count rates otherwise you get new values every 100 ms
    case 'SYNCRATE'
        % current sync rate
        stringPre = 'HH_Get';
        stringLib = 'SyncRate';
        if N_varargin < 1  % read
            out =  0;
            outPtr =  libpointer('int32Ptr', out);
            [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
            checkStatus(ret, [stringPre stringLib])
            varargout{1} = out;
        else  % set
            fprintf('\nNot implemented. \n');
        end
    case 'WARNINGS'
        % warnings (numeric) for the device
        hydra('taux'); % must be called before to have valid warnings
        stringPre = 'HH_Get';
        stringLib = 'Warnings';
        out =  0;
        outPtr =  libpointer('int32Ptr', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;
    case 'WARNINGSTEXT'
        % warnings (text) for the device
        stringPre = 'HH_Get';
        stringLib = 'WarningsText';
        Warnings = hydra('WARNINGS');
        out =  blanks(16384); %enough length!
        outPtr =  libpointer('cstring', out);
        [ret, out] =  calllib('HHlib', [stringPre stringLib], HydraHarpDevice(1), outPtr, Warnings);
        checkStatus(ret, [stringPre stringLib])
        varargout{1} = out;
    otherwise
        fprintf('Fonction non valide')
        return;
end
end

%**************************************************************************
%**************************************************************************

function bin = binning(resolution)
%Fonction permettant de transformer une resolution en ps en le ''binning''
%adequat pour le programme.

%resolution entre 1 et 1024 ps
bin = 0;
while resolution>1
    resolution = resolution/2;
    bin = bin+1;
end
if bin>10
    bin = 10;
end

% 0 =  1x base resolution,
% 1 =  2x base resolution,
% 2 =  4x base resolution,
% 3 =  8x base resolution, and so on.
end

function out = setInRange(in, min, max)
%contraint in dans l'intervale min <= in <= max

if in < min
    in = min
elseif in > max
    in = max
end
out = in;

end

function checkStatus(status, string)
if (status<0)
    fprintf([string ' error %ld. Aborted.\n'], status);
    hydra('stop')
    return;
end;

end







































































