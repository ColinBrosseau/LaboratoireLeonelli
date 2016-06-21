function varargout = sr400(fonction,varargin)
%   varargout = sr400(fonction,varargin)
%
%fonction de controle du compteur de photon SR400
%Exemples:
%   sr400('initialise')
%   [A,B,tout_A,tout_B] = sr400('mesure_compteur');
%   sr400('start')
%   sr400('stop')
%   sr400('ENREGISTRE_CONFIGURATION',fichier) % Sauvegarde l'etat du SR400 dans un fichier.m.
%
% fonction
%   BITS_ETATS  
%               Lit les bits d'etat (Status Byte) du compteur de photons
%               Voir sr400('SS')
%   CL          counter reset
%   COUNTER_INPUT
%               Selectionne l'entree du compteur
%               input = sr400('COUNTER_INPUT',counteur,{input})
%                   counter    allowed input
%                    A          '10 MHz', 'Input 1'
%                    B          'Input 1', 'Input 2'
%                    T          '10 MHz', 'Input 2', 'Trig'
%   COUNT_MODE          
%               Count Mode
%               mode = sr400('COUNT_MODE',{mode})
%                   mode
%                    'A,B for T preset'
%                    'A-B for T preset'
%                    'A+B for T preset'
%                    'A for B preset'
%   COUNTER_PRESET
%               Counter Preset pour ajuster le temps de la mesure
%               input = sr400('COUNTER_PRESET',counteur,{N})
%                   counter    N
%                    B          1 chiffre significatif
%                    T                   
%   DISC_SLOPE  
%               Discrimator Slope
%               sr400('DISC_SLOPE',compteur,{slope})
%                   compteur    slope
%                    'A'         'RISE'
%                    'B'         'FALL'
%                    'T'
%   DISC_MODE
%               Discrimator Mode
%               sr400('DISC_MODE',compteur,{mode})
%                   compteur    mode
%                    'A'         'FIXED'
%                    'B'         'SCAN'
%                    'T'
%   DISC_STEP
%               Discrimator Scan Step Size
%               sr400('DISC_STEP',compteur,{step})
%                   compteur    -0.0200V <= step <= +0.0200V
%                    'A'         
%                    'B'         
%                    'T'
%   DISC_LEVEL
%               Discrimator Level
%               sr400('DISC_LEVEL',compteur,{level})
%                   compteur    -0.3000V <= step <= +0.3000V
%                    'A'         
%                    'B'        
%                    'T'
%   DISPLAY_MODE
%               Display mode
%               sr400('DISPLAY_MODE',{mode})
%                   mode    
%                    'CONTINUOUS'         
%                    'HOLD'        
%   DWELL_TIME
%               Temps d'attente entre les mesures. Utile seulement pour les
%               tables traçantes.
%               sr400('DWELL_TIME',{dwell_time})
%                   dwell_time
%                    2e-3 s <= dwell_time <= 60 s
%                    Si dwell_time = 0: DWEll is set to External
%   EA          Lit les données mesurées contenues dans le compteur A
%   EB          Lit les données mesurées contenues dans le compteur B
%   ENREGISTRE_CONFIGURATION
%               Sauvegarde l'etat du SR400 dans un fichier (*.m)
%               sr400('ENREGISTRE_CONFIGURATION',fichier)
%   GATE_DELAY
%               Gate delay: temps d'ouverture de la porte temporelle après
%               le signal de trig
%               sr400('GATE_DELAY',compteur,{temps})
%                   Compteur    temps 
%                    'A'         0 <= temps <= 999.2e-3 s  
%                    'B'         
%   GATE_STEP
%               Gate delay scan step
%               sr400('GATE_STEP',compteur,{temps})
%                   Compteur  temps
%                    'A'       0 <= temps <= 99.92e-3 s   
%                    'B'         
%   GATE_MODE 
%               Gate Mode
%               sr400('GM',compteur,{mode})
%                   Compteur    mode
%                    'A'         'CW'       mesure en continu
%                    'B'         'FIXED'    
%                                'SCAN'
%   GATE_WIDTH
%               Gate width: duree d'ouverture de la porte en seconde
%               sr400('GATE_WIDTH',compteur,{temps})
%                   Compteur    temps
%                    'A'         5e-9 s <= temps <= 999.2e-3 s  
%                    'B'         
%   GET_COUNTER 
%               Lit les donnees prises
%               [somme_des_valeurs,toutes_les_valeurs] = sr400('GET_COUNTER',counter)
%                   counter       
%                    0,'0','A'       
%                    1,'1','B'    
%   initialise  
%               Initialise la communication par le port GPIB
%               sr400('initialise')                 %L'adresse GPIB est 23
%               sr400('initialise',ADRESSE_GPIB)    
%   MESURE_COMPTEUR
%               [A,B,tout_A,tout_B] = sr400('mesure_compteur');
%               Fait une mesure et retourne les resultats
%   N_PERIODS
%               number of periods in a scan (N periods)
%               sr400('N_PERIODS',{N}); ecriture
%                   1 <= N <= 2000
%               sortie string
%   NN          retourne la Scan position du SR400
%               sr400('NN')
%   MD          Change l'affichage du compteur de photons 
%               a l'endroit voulu (voir sr400.m pour details)
%   PORT_MODE   
%               Mode du port output D/A du SR400
%               sr400('PORT_MODE',port,{mode})
%                   port        mode
%                    'PORT 1'    'FIXED'
%                    'PORT 2'    'SCAN'
%   PORT_STEP   
%               Scan Step du port output D/A du SR400
%               sr400('PORT_STEP',port,{step})
%                   port        step
%                    'PORT 1'    -0.500V <= step <= 0.500V
%                    'PORT 2'    
%   PORT_LEVEL   
%               Niveau du port output D/A du SR400
%               sr400('PORT_MODE',port,{level})
%                   port        level
%                    'PORT 1'    -10.00V <= level <= +10.00V
%                    'PORT 2'   
%   RESET_COUNTER 
%               Reinitialise tous les compteurs
%               sr400('RESET_COUNTER')
%   SCAN_END_MODE ou AT_N 
%               sr400('SCAN_END_MODE',{mode})
%                   mode
%                    'START'
%                    'STOP'
%   SHUTTER
%               sr400('SHUTTER','ouvert');  ouvre le shutter
%               sr400('SHUTTER','FERME');   ferme le shutter
%
%               Controle le shutter mecanique
%               On suppose que, pour la boite de controle du shutter, 5V =
%               ferme et que 0V = ouvert.
%               Connecter la boite de controle du shutter sur (PORT1 OUT) a
%               l'arriere du SR400 
%   SS          Lit les bits d'etat (Status Byte) du compteur de photons
%               et tous les bits d'etats sont reinitialises
%               out = sr400('SS',j) 
%                   %j: bit a lire (numerique ou chaine de caractere)
%                           0-7
%               out = sr400('SS') Si j est omis, SS retourne tous les bits d'etat
%               Sortie binaire
%   START       Demare l'acquisition
%               sr400('start')
%   STOP        Arrete l'acquisition
%               sr400('stop')
%               Met le scan en Pause si un scan est en marche
%               Si le scan est en Pause, fait un Reset des compteurs
%   TRIG_LEVEL  
%               Gate Trigger Level
%               sr400('TRIG_LEVEL',{T_LVL})
%                   -2V <= T_LVL <= 2V     
%   TRIG_SLOPE  
%               Gate Trigger Slope
%               sr400('TRIG_SLOPE',{slope})
%                   slope
%                    'RISE'
%                    'FALL'
%
%Utilise la fonction 'gpib' du 'package' gpib de Tom Davis
%   que l'on peut trouver à l'adresse 
%   http://www.mathworks.com/matlabcentral/fileexchange/216
%Utilise les fonctions ibfind, ibpad, ibrsc, ibsic et ibsre 
%   du 'package' NI GPIB toolbox de Alaa Makdissi
%   que l'on peut trouver à l'adresse 
%   http://www.mathworks.com/matlabcentral/fileexchange/3140
%
%Colin Decembre 2005

global SR400
global SR400_PRESENT

if isempty(SR400)
    initialise_SR400(23) %l'addresse par defaut est 23
end

switch upper(fonction)
%Fonctions 'utilitaires' du compteur de photons
case 'CHARGE_CONFIGURATION'
    disp('Il suffit de charger le fichier .m de la ligne de commande de Matlab.')
case 'ENREGISTRE_CONFIGURATION'
    if nargin==1 
        [fichier,nom_repertoire,FilterIndex] = uiputfile('.m','Fichier de sauvegarde de la configuration du SR400');
        fichier = [nom_repertoire fichier];
    else
        fichier = varargin{1};
    end
    if ~strcmp(fichier(end-1:end),'.m')
        fichier = [fichier '.m'];
    end
    fid = fopen(fichier,'w');
    fprintf(fid,'sr400(''initialise'');\n');
    fprintf(fid,'sr400(''COUNT_MODE'', ''%s'');\n',sr400('COUNT_MODE'));
    fprintf(fid,'sr400(''COUNTER_INPUT'', ''A'', ''%s'');\n',sr400('COUNTER_INPUT','A'));
    fprintf(fid,'sr400(''COUNTER_INPUT'', ''B'', ''%s'');\n',sr400('COUNTER_INPUT','B'));
    switch sr400('COUNT_MODE')
    case 'A FOR B PRESET'
        fprintf(fid,'sr400(''counter_preset'', ''B'', ''%s'');\n',sr400('counter_preset','B'));       
    otherwise
        fprintf(fid,'sr400(''COUNTER_INPUT'', ''T'', ''%s'');\n',sr400('COUNTER_INPUT','T'));
        fprintf(fid,'sr400(''counter_preset'', ''T'', ''%s'');\n',sr400('counter_preset','T'));
    end
    fprintf(fid,'sr400(''N_PERIODS'', ''%s'');\n',sr400('N_PERIODS'));
    fprintf(fid,'sr400(''SCAN_END_MODE'', ''%s'');\n',sr400('SCAN_END_MODE'));
    fprintf(fid,'sr400(''DWELL_TIME'', ''%s'');\n',sr400('DWELL_TIME'));
    fprintf(fid,'sr400(''DISPLAY_MODE'', ''%s'');\n',sr400('DISPLAY_MODE'));
    fprintf(fid,'sr400(''GATE_MODE'', ''A'', ''%s'');\n',sr400('GATE_MODE','A'));
    switch sr400('GATE_MODE','A')
    case 'FIXED'
        fprintf(fid,'sr400(''GATE_DELAY'', ''A'', ''%s'');\n',sr400('GATE_DELAY','A'));
        fprintf(fid,'sr400(''GATE_WIDTH'', ''A'', ''%s'');\n',sr400('GATE_WIDTH','A'));
    case 'SCAN'
        fprintf(fid,'sr400(''GATE_STEP'', ''A'', ''%s'');\n',sr400('GATE_STEP','A'));
        fprintf(fid,'sr400(''GATE_DELAY'', ''A'', ''%s'');\n',sr400('GATE_DELAY','A'));
        fprintf(fid,'sr400(''GATE_WIDTH'', ''A'', ''%s'');\n',sr400('GATE_WIDTH','A'));
    end
    fprintf(fid,'sr400(''GATE_MODE'', ''B'', ''%s'');\n',sr400('GATE_MODE','B'));
    switch sr400('GATE_MODE','B')
    case 'FIXED'
        fprintf(fid,'sr400(''GATE_DELAY'', ''B'', ''%s'');\n',sr400('GATE_DELAY','B'));
        fprintf(fid,'sr400(''GATE_WIDTH'', ''B'', ''%s'');\n',sr400('GATE_WIDTH','B'));
    case 'SCAN'
        fprintf(fid,'sr400(''GATE_STEP'', ''B'', ''%s'');\n',sr400('GATE_STEP','B'));
        fprintf(fid,'sr400(''GATE_DELAY'', ''B'', ''%s'');\n',sr400('GATE_DELAY','B'));
        fprintf(fid,'sr400(''GATE_WIDTH'', ''B'', ''%s'');\n',sr400('GATE_WIDTH','B'));
    end
    fprintf(fid,'sr400(''TRIG_SLOPE'', ''%s'');\n',sr400('TRIG_SLOPE'));
    fprintf(fid,'sr400(''TRIG_LEVEL'', ''%s'');\n',sr400('TRIG_LEVEL'));
    fprintf(fid,'sr400(''DISC_SLOPE'', ''A'', ''%s'');\n',sr400('DISC_SLOPE','A'));
    fprintf(fid,'sr400(''DISC_MODE'', ''A'', ''%s'');\n',sr400('DISC_MODE','A'));
    switch sr400('DISC_MODE','A')
    case 'SCAN'
        fprintf(fid,'sr400(''DISC_STEP'', ''A'', ''%s'');\n',sr400('DISC_STEP','A'));
    end
    fprintf(fid,'sr400(''DISC_LEVEL'', ''A'', ''%s'');\n',sr400('DISC_LEVEL','A'));
    fprintf(fid,'sr400(''DISC_SLOPE'', ''B'', ''%s'');\n',sr400('DISC_SLOPE','B'));
    fprintf(fid,'sr400(''DISC_MODE'', ''B'', ''%s'');\n',sr400('DISC_MODE','B'));
    switch sr400('DISC_MODE','B')
    case 'SCAN'
        fprintf(fid,'sr400(''DISC_STEP'', ''B'', ''%s'');\n',sr400('DISC_STEP','B'));
    end
    fprintf(fid,'sr400(''DISC_LEVEL'', ''B'', ''%s'');\n',sr400('DISC_LEVEL','B'));
    fprintf(fid,'sr400(''DISC_SLOPE'', ''T'', ''%s'');\n',sr400('DISC_SLOPE','T'));
    fprintf(fid,'sr400(''DISC_MODE'', ''T'', ''%s'');\n',sr400('DISC_MODE','T'));
    fprintf(fid,'sr400(''DISC_STEP'', ''T'', ''%s'');\n',sr400('DISC_STEP','T'));
    fprintf(fid,'sr400(''DISC_LEVEL'', ''T'', ''%s'');\n',sr400('DISC_LEVEL','T'));
    fprintf(fid,'sr400(''PORT_MODE'', ''PORT 1'', ''%s'');\n',sr400('PORT_MODE','PORT 1'));
    switch sr400('PORT_MODE','PORT 1')
    case 'SCAN'
        fprintf(fid,'sr400(''PORT_STEP'', ''PORT 1'', ''%s'');\n',sr400('PORT_STEP','PORT 1'));
    end
    fprintf(fid,'sr400(''PORT_LEVEL'', ''PORT 1'', ''%s'');\n',sr400('PORT_LEVEL','PORT 1'));
    fprintf(fid,'sr400(''PORT_MODE'', ''PORT 2'', ''%s'');\n',sr400('PORT_MODE','PORT 2'));
    switch sr400('PORT_MODE','PORT 2')
    case 'SCAN'
        fprintf(fid,'sr400(''PORT_STEP'', ''PORT 2'', ''%s'');\n',sr400('PORT_STEP','PORT 2'));
    end
    fprintf(fid,'sr400(''PORT_LEVEL'', ''PORT 2'', ''%s'');\n',sr400('PORT_LEVEL','PORT 2'));
    out = fclose(fid);
    switch out
    case 0
        disp('Configuration du SR400 enregistree ')
        disp(['  avec succes dans le fichier: ' fichier])
    case -1
        disp(['Erreur dans l''enregistrement de la configuration du SR400' ])
    end
case 'GET_COUNTER'
    counter  = conversion_counter_lettre(varargin{1});
    toutes_les_valeurs = sr400(['E' counter]);
    somme_des_valeurs = sum(toutes_les_valeurs); 
    varargout{1} = somme_des_valeurs;
    varargout{2} = toutes_les_valeurs;
case {'INITIALISE'}
    global SR400
    SR400 = [];
    sr400('') %l'addresse par defaut est 23
case 'MESURE_COMPTEUR'
    vider_scrap_compteur;
    while (bitand(bin2dec(sr400('BITS_ETATS')), 6) ~= 0)
    end
    while (bitand(bin2dec(sr400('BITS_ETATS')), 128) ~= 0)
    end
    SS = sr400('BITS_ETATS'); %lit les bits d'etats du compteur
    % SV = SV_SR400(compteur,22); % ajuste la condition pour que le compteur envoi un SRQ: fini de compte+data ready+rate error(probleme du materiel)
    %je m'assure que la condition pour generer un SRQ est bien 22
    %je l'ai deactive car ca prend BEAUCOUP de temps et je ne l'utilise pas
    %  while (bitand(bin2dec(SV_SR400(compteur,22)), 22) <= 6)
    %  end
    %SV = SV_SR400(compteur);
    %SS = SS_SR400(compteur); 
    scan_end_mode = sr400('SCAN_END_MODE'); %sauvegarde l'etat initial du compteur
    sr400('SCAN_END_MODE','STOP'); %le compteur arrete apres la mesure
    vider_scrap_compteur;
    t_initial=cputime; %initialisation du temps ecoule
    sr400('RESET_COUNTER'); %initialise les compteurs du compteur de photons
    %DEMARE L'ACQUISITION
    sr400('START');  %demarrer l'acquisition
    sr400('MD',1,5); %Met l'affichage du SR400 sur N_period (ou est rendue l'acquitision) 
    attendre_compteur
    t_final=cputime-t_initial;
    [spr,ibsta]=gpib('rsp',SR400);
    while (bitand(ibsta, 2048)  ~= 0) %i.e. Device requesting service
        [spr,ibsta]=gpib('rsp',SR400);
    end
    [A,tout_A] = sr400('get_counter','a'); %lit les donnees sur le comteur A
    [B,tout_B] = sr400('get_counter','B'); %lit les donnees sur le comteur B
    sr400('SCAN_END_MODE',scan_end_mode); %on remet le compteur dans son etat initial
    sr400('RESET_COUNTER'); %initialise les compteurs du compteur de photons
    sr400('START');  %demarrer l'acquisition
    varargout{1} = A;
    varargout{2} = B;
    varargout{3} = tout_A;
    varargout{4} = tout_B;
case 'SHUTTER'
    %Controle le shutter mecanique
    %On suppose que, pour la boite de controle du shutter, 5V = ferme et
    %que 0V = ouvert.
    %Connecter la boite de controle du shutter sur PORT1 a l'arriere du
    %SR400
    %fonction speciale
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        switch upper(nouvel_argument)
        case 'OUVERT'
            nouvel_argument='0';
        case 'FERME'
            nouvel_argument='5';
        end   
        sr400('PORT_MODE','PORT 1','FIXED');
        sta = sr400('PORT_LEVEL','PORT 1',nouvel_argument); 
        varargout{1} = sr400(fonction);
    else %lecture
        level = str2num(sr400('PORT_LEVEL','PORT 1'));
        switch level
            case 0
                etat = 'OUVERT';
            case 5
                etat = 'FERME';
            otherwise
                etat = 'INDEFINI';
        end
        varargout{1} = etat;
    end
%Fonctions ALIAS
case {'START','STOP','RESET_COUNTER'}
    %fonctions  ALIAS
    %           x parametre
    %           0 sortie
    switch upper(fonction)
    case 'START'
        fonction = 'CS';
    case 'STOP'
        fonction = 'CH';
    case 'RESET_COUNTER'
        fonction = 'CR';
    end
    sr400(fonction,varargin{:})
case {'AT_N','DWELL_TIME','DISPLAY_MODE','N_PERIODS','SCAN_END_MODE','BITS_ETATS','GATE_STEP','GATE_DELAY','GATE_MODE','GATE_WIDTH','COUNT_MODE','COUNTER_INPUT','COUNTER_PRESET','TRIG_LEVEL','TRIG_SLOPE','DISC_SLOPE','DISC_MODE','DISC_STEP','DISC_LEVEL','PORT_MODE','PORT_STEP','PORT_LEVEL'}
    %fonctions  ALIAS
    %           x parametre
    %           1 sortie
    switch upper(fonction)
    case 'AT_N'
        fonction = 'NE';
    case 'BITS_ETATS'
        fonction = 'SS';
    case 'COUNT_MODE'
        fonction = 'CM';
    case 'COUNTER_INPUT'
        fonction = 'CI';
    case 'COUNTER_PRESET'
        fonction = 'CP';        
    case 'DISC_SLOPE'
        fonction = 'DS';        
    case 'DISC_MODE'
        fonction = 'DM';        
    case 'DISC_STEP'
        fonction = 'DY';        
    case 'DISC_LEVEL'
        fonction = 'DL';  
    case 'DISPLAY_MODE'
        fonction = 'SD';  
    case 'DWELL_TIME'
        fonction = 'DT';        
    case 'GATE_STEP'
        fonction = 'GY';
    case 'GATE_DELAY'
        fonction = 'GD';
    case 'GATE_MODE'
        fonction = 'GM';
    case 'GATE_WIDTH'
        fonction = 'GW';
    case 'N_PERIODS'
        fonction = 'NP';
    case 'PORT_MODE'
        fonction = 'PM';
    case 'PORT_STEP'
        fonction = 'PY';
    case 'PORT_LEVEL'
        fonction = 'PL';
    case 'SCAN_END_MODE'
        fonction = 'NE';
    case 'TRIG_LEVEL'
        fonction = 'TL';
    case 'TRIG_SLOPE'
        fonction = 'TS';
    end
    varargout{1} = sr400(fonction,varargin{:});
%Fonctions de base du compteur de photons
case {'CH','CL','CR','CS'}
    %fonctions  0 parametre
    %           0 sortie
    gpib('wrt',SR400,[fonction char(13) char(10)]);
case 'CI'
    %fonction speciale
    counter = conversion_counter(varargin{1});
    if nargin==2 %lecture
        %vider_scrap_compteur;
        gpib('wrt',SR400, [fonction counter]);
        out = str2num(gpib('rd', SR400));%lit l'input du compteur
        switch out
        case 0
            varargout{1} = '10 MHz';
        case 1  
            varargout{1} = 'INPUT 1';
        case 2
            varargout{1} = 'INPUT 2';
        case 3
            varargout{1} = 'TRIG';
        end
    else %ecriture
        input_counter = conversion_input(varargin{2});
        gpib('wrt',SR400, [fonction counter ',' input_counter]);
        varargout{1} = sr400(fonction,counter);
    end
case 'CM' 
    %fonction speciale
    if nargin==1 %lecture
        gpib('wrt',SR400,fonction);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'A,B FOR T PRESET';
        case 1  
            varargout{1} = 'A-B FOR T PRESET';
        case 2
            varargout{1} = 'A+B FOR T PRESET';
        case 3
            varargout{1} = 'A FOR B PRESET';
        end
    else  %ecriture
        mode = varargin{1};
        switch upper(mode)
        case 'A,B FOR T PRESET'
            mode = '0';
        case 'A-B FOR T PRESET'
            mode = '1';
        case 'A+B FOR T PRESET'
            mode = '2';
        case 'A FOR B PRESET'
            mode = '3';
        end
        gpib('wrt',SR400, [fonction mode]);
        varargout{1} = sr400(fonction);
    end
case {'CP'}
    %fonction speciale
    %counter preset
    counter = conversion_counter(varargin{1});
    if counter ~= '0';% on ne peut pas faire Preset counter sur le compteur A
        if nargin==2 %lecture
            %vider_scrap_compteur;
            gpib('wrt',SR400, [fonction counter]);
            out = gpib('rd', SR400);%lit l'input du compteur
            if double(out(end)) == 10; out = out(1:end-1); end
            if double(out(end)) == 13; out = out(1:end-1); end
            varargout{1} = out;
        else %ecriture
            nouvel_argument = varargin{2};
            if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
            gpib('wrt',SR400, [fonction counter ',' nouvel_argument]);
            varargout{1} = sr400(fonction,counter);
        end
    end
case {'DS'}
    %fonction speciale
    counter = conversion_counter(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'RISE';
        case 1  
            varargout{1} = 'FALL';
        end
    else %ecriture
        mode = varargin{2};
        switch upper(mode)
        case {'RISE',0,'0'}   
            mode = '0';
        case {'FALL',1,'1'}
            mode = '1';
        end
        gpib('wrt',SR400, [fonction counter ',' mode]);
        varargout{1} = sr400(fonction,counter);
    end
case {'DM'}
    %fonction speciale
    counter = conversion_counter(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'FIXED';
        case 1  
            varargout{1} = 'SCAN';
        end
    else %ecriture
        mode = varargin{2};
        switch upper(mode)
        case {'FIXED',0,'0'}   
            mode = '0';
        case {'SCAN',1,'1'}
            mode = '1';
        end
        gpib('wrt',SR400, [fonction counter ',' mode]);
        varargout{1} = sr400(fonction,counter);
    end
case {'EA','EB'}
    %fonction tres speciale
    %Lit les données mesurées contenues dans les compteurs
    N = str2num(sr400('N_Periods')); %nombre de donnees dans la mesure
    out = ones(N,1)*nan; %vecteur des resultats
    gpib('wrt', SR400, [fonction char(13) char(10)]);
    for i=1:N %lit les points un a un
        pause(.01)
        out(i) = str2num(gpib('rd', SR400));%lit les resultat de chaque mesure
    end
    varargout{1} = out;
case {'FA','FB'}
    %fonction tres speciale
    %Demarre un nouveau scan
    %retourne les donnees des qu'elles sont pretes
%     scan_end_mode = sr400('SCAN_END_MODE'); %sauvegarde l'etat initial du compteur
    sr400('SCAN_END_MODE','STOP'); %le compteur arrete apres la mesure
    sr400('RESET_COUNTER')
    N = str2num(sr400('N_Periods')); %nombre de donnees dans la mesure
    out = ones(N,1)*nan; %vecteur des resultats
    gpib('wrt', SR400, [fonction char(13) char(10)]);
    for i=1:N %lit les points un a un
        pause(.01)
        out(i) = str2num(gpib('rd', SR400));%lit les resultat de chaque mesure
    end
%     sr400('SCAN_END_MODE',scan_end_mode); %on remet le compteur dans son etat initial
%     sr400('RESET_COUNTER'); %initialise les compteurs du compteur de photons
%     sr400('START');  %demarrer l'acquisition
    varargout{1} = out;
case {'GM'}
    %fonction speciale
    counter = conversion_counter(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'CW';
        case 1  
            varargout{1} = 'FIXED';
        case 2
            varargout{1} = 'SCAN';
        end
    else %ecriture
        mode = varargin{2};
        switch upper(mode)
        case {'0',0,'CW'}   
            mode = '0';
        case {'1',1,'FIXED'}
            mode = '1';
        case {'2',2,'SCAN'}
            mode = '2';
        end
        gpib('wrt',SR400, [fonction counter ',' mode]);
        varargout{1} = sr400(fonction,counter);
    end
case {'GY','GD','GW','DY','DL'}
    %fonctions  compteur +  0-1 parametre
    %           1 sortie
    counter = conversion_counter(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = gpib('rd', SR400);%lit le mode de comptage
         if double(out(end)) == 10; out = out(1:end-1); end
         if double(out(end)) == 13; out = out(1:end-1); end
         varargout{1} = out;
    else %ecriture
         temps = num2str(varargin{2});
         gpib('wrt',SR400, [fonction counter ',' temps char(10)]);
         varargout{1} = sr400(fonction,counter);
    end
case 'NE'
    %fonction speciale
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        switch upper(nouvel_argument)
        case 'START'
            nouvel_argument='1';
        case 'STOP'
            nouvel_argument='0';
        end   
        if ~isstr(nouvel_argument); error(['Le parametre de ' fonction ' doit etre une chaine de caracteres ou un nombre']); end
        sta = gpib('wrt', SR400, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr400(fonction);
    else %lecture
        sta = gpib('wrt', SR400, [fonction char(10)]);
        scan_end_mode = str2num(gpib('rd', SR400));
        switch scan_end_mode
        case 0
            scan_end_mode='STOP';
        case 1
            scan_end_mode='START';
        end   
        varargout{1} = scan_end_mode;
        check_error(sta)
    end   
case 'NN'
    %fonction  0 parametre
    %           1 sortie numerique
    sta = gpib('wrt', SR400, [fonction char(10)]);
    varargout{1} = str2num(gpib('rd', SR400));
    check_error(sta)
case {'NP','TL'}
    %fonction  0-1 parametre
    %          1 sortie string
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        sta = gpib('wrt', SR400, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr400(fonction);
    else %lecture
        sta = gpib('wrt', SR400, [fonction char(10)]);
        out = gpib('rd', SR400);
        if double(out(end)) == 10; out = out(1:end-1); end
        if double(out(end)) == 13; out = out(1:end-1); end
        varargout{1} = out;
        check_error(sta)
    end   
case {'DT'}
    %fonction speciale
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        if strcmp(upper(nouvel_argument),'EXTERNAL'); nouvel_argument='0'; end
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        sta = gpib('wrt', SR400, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr400(fonction);
    else %lecture
        sta = gpib('wrt', SR400, [fonction char(10)]);
        out = gpib('rd', SR400);
        if str2num(out) == 0; out='EXTERNAL'; end
        if double(out(end)) == 10; out = out(1:end-1); end
        if double(out(end)) == 13; out = out(1:end-1); end
        varargout{1} = out;
        check_error(sta)
    end   
case 'MD'
    %sr400('MD',j,k)
    %Change l'affichage du compteur de photons
    %a l'endroit voulu
    %
    %   j,k  AFFICHAGE
    %------------------------
    % 1,1   Count
    %   2   A
    %   3   B
    %   4   T
    %   5   N Periods
    %   6   At n
    %   7   D/A out
    %   8   D/A range
    %   9   Display
    %       
    % 2,1   A gate
    %   2   A Delay
    %   3   A Width
    %       
    % 3,1   B Gate
    %   2   B Delay
    %   3   B Width
    %       
    % 4,1   Trig slope
    %   2   Trig lvl
    %   3   A disc slope
    %   4   A disc mode
    %   5   A disc lvl
    %   6   B disc slope
    %   7   B disc lvl
    %   8   B disc lvl
    %   9   T disc slope
    %   10  T disc lvl
    %   11  T disc lvl
    %   12  Port1 mode
    %   13  Port1 lvl
    %   14  Port2 mode
    %   15  Port2 lvl
    %       
    % 5,1   GPIB addr
    %   2   RS232 baud
    %   3   RS232 bits
    %   4   RS232 parity
    %   5   RS232 wait
    %   6   RS232 echo
    %   7   Data
    %       
    % 6,1   LCD contrast
    %   2   Store
    %   3   Recall
    j = varargin{1};
    k = varargin{2};
        
    if isnumeric(j)
        j=num2str(j);
    end
    if isnumeric(k)
        k=num2str(k);
    end
    
    if isstr(j)&isstr(k)
        gpib('wrt',SR400, ['MD' j ',' k]);
    else
        error('Les parametres de MD_SR400 doivent etre une chaine de caracteres ou un nombre');
    end
case {'PM'}
    %fonction speciale
    %port
    counter = conversion_port(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'FIXED';
        case 1  
            varargout{1} = 'SCAN';
        end
    else %ecriture
        mode = varargin{2};
        switch upper(mode)
        case {'FIXED',0,'0'}   
            mode = '0';
        case {'SCAN',1,'1'}
            mode = '1';
        end
        gpib('wrt',SR400, [fonction counter ',' mode]);
        varargout{1} = sr400(fonction,counter);
    end
case {'PY','PL'}
    %fonctions  port +  0-1 parametre
    %           1 sortie
    counter = conversion_port(varargin{1});
    if nargin==2 %lecture
        gpib('wrt',SR400, [fonction counter]);
        out = gpib('rd', SR400);%lit le mode de comptage
        if double(out(end)) == 10; out = out(1:end-1); end
        if double(out(end)) == 13; out = out(1:end-1); end
        varargout{1} = out;
    else %ecriture
         temps = num2str(varargin{2});
         gpib('wrt',SR400, [fonction counter ',' temps]);
         varargout{1} = sr400(fonction,counter);
    end
case 'SD'
    %fonction speciale
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        switch upper(nouvel_argument)
        case 'CONTINUOUS'
            nouvel_argument='0';
        case 'HOLD'
            nouvel_argument='1';
        end   
        if ~isstr(nouvel_argument); error(['Le parametre de ' fonction ' doit etre une chaine de caracteres ou un nombre']); end
        sta = gpib('wrt', SR400, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr400(fonction);
    else %lecture
        sta = gpib('wrt', SR400, [fonction char(10)]);
        scan_end_mode = str2num(gpib('rd', SR400));
        switch scan_end_mode
        case 0
            scan_end_mode='CONTINUOUS';
        case 1
            scan_end_mode='HOLD';
        end   
        varargout{1} = scan_end_mode;
        check_error(sta)
    end   
case 'SS'
    if nargin > 1 %lit le bit specifie
        nouvel_argument = varargin{1};
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        if ~isstr(nouvel_argument); error(['Le parametre de ' fonction ' doit etre une chaine de caracteres ou un nombre']); end
        sta = gpib('wrt', SR400, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = gpib('rd', SR400);
        check_error(sta)
    else %lit tous les bits
        sta = gpib('wrt', SR400, [fonction char(10)]);
        pause(.1)
        varargout{1} = dec2bin(str2num(gpib('rd', SR400)));
        check_error(sta)
    end    
case 'TS'
    if nargin==1 %lecture
        gpib('wrt',SR400,fonction);
        out = str2num(gpib('rd', SR400));%lit le mode de comptage
        switch out
        case 0
            varargout{1} = 'RISE';
        case 1  
            varargout{1} = 'FALL';
        end
    else  %ecriture
        mode = varargin{1};
        switch upper(mode)
        case 'RISE'
            mode = '0';
        case 'FALL'
            mode = '1';
        end
        gpib('wrt',SR400, [fonction mode]);
        varargout{1} = sr400(fonction);
    end
otherwise 
    %disp('fonction pas encore implementee')
end

%met le SR400 sur la bonne fenetre d'affichage pour que l'on puisse voir le changement
switch upper(fonction)
case {'CM'}
    sr400('md',1,1)
case {'CI','CP'}
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',1,2)
    case '1'
        sr400('md',1,3)
    case '2'
        sr400('md',1,4)
    end     
case {'NP'}    
    sr400('md',1,5)
case {'NE','DT'}    
    sr400('md',1,6)
case {'GM','GY'}
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',2,1)
    case '1'
        sr400('md',3,1)
    end     
case {'GD'}
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',2,2)
    case '1'
        sr400('md',3,2)
    end     
case {'GW'}
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',2,3)
    case '1'
        sr400('md',3,3)
    end     
case {'TS'}    
    sr400('md',4,1)
case {'TL'}    
    sr400('md',4,2)
case {'DS'}    
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',4,3)
    case '1'
        sr400('md',4,6)
    case '2'
        sr400('md',4,9)
    end     
case {'DM','DY'}    
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',4,4)
    case '1'
        sr400('md',4,7)
    case '2'
        sr400('md',4,10)
    end     
case {'DL'}    
    counter = conversion_counter(varargin{1});
    switch counter
    case '0'
        sr400('md',4,5)
    case '1'
        sr400('md',4,8)
    case '2'
        sr400('md',4,11)
    end     
case {'PM','PY'}    
    port = conversion_port(varargin{1});
    switch port
    case '1'
        sr400('md',4,12)
    case '2'
        sr400('md',4,14)
    end     
case {'PL'}    
    port = conversion_port(varargin{1});
    switch port
    case '1'
        sr400('md',4,13)
    case '2'
        sr400('md',4,15)
    end     
end



%****************************************************************

function out = conversion_counter(in)
%converti les differentes denominations des compteurs avec 
% la forme standard demandee par le SR400
switch upper(in)
case {'A','0',0}
    out = '0';
case {'B','1',1}
    out = '1';
case {'TRIG','T','2',2}
    out = '2';
otherwise
    error('Les parametres de compteur doivent etre une chaine de caracteres ou un nombre');
end

function out = conversion_counter_lettre(in)
%converti les differentes denominations des compteurs 
% en lettre: 'A', 'B' ou 'T'
switch upper(in)
case {'A','0',0}
    out = 'A';
case {'B','1',1}
    out = 'B';
case {'TRIG','T','2',2}
    out = 'T';
otherwise
    error('Les parametres de compteur doivent etre une chaine de caracteres ou un nombre');
end

function out = conversion_port(in)
%converti les differentes denominations des compteurs avec 
% la forme standard demandee par le SR400
switch upper(in)
case {'PORT 1','PORT1','1',1}
    out = '1';
case {'PORT 2','PORT1','2',2}
    out = '2';
otherwise
    error('Les parametres de port doivent etre une chaine de caracteres ou un nombre');
end

function out = conversion_input(in)
%converti les differentes denominations des entrees avec 
% la forme standard demandee par le SR400
switch upper(in)
case {'10 MHZ','10',10}
    out = '0';
case {'INPUT 1','1',1}
    out = '1';
case {'INPUT 2','2',2}
    out = '2';
case {'TRIG','3',3}
    out = '3';
otherwise
    error('Les parametres d''input doivent etre une chaine de caracteres ou un nombre');
end

function initialise_SR400(addresse)
%initialise_SR400(addresse)
%initialise le compteur de photons SR400
global ud0
global SR400
%
if ud0 ~= ibfind('gpib0')
    ud0 = ibfind('gpib0');
    ibsta = ibpad(ud0,0);
    ibsta = ibrsc(ud0,1);
    ibsta = ibsic(ud0);
    ibsta = ibsre(ud0,1);
    disp('-----------------------------------------')
    disp('Status gpib0');
    status_check(ibsta);
    disp('-----------------------------------------')
end
%
SR400 = gpib('dev', 0, addresse, 0, 13, 1, 0);
%ibsta=gpib('wrt', SR400, ['sdc' char(13) char(10)]);%initialise le SR400 (commande de remplacement a clr)
ibsta = gpib('wrt', SR400, ['IFC  DCL UNT UNL REN MTA LISTEN 23 SPE SDC']); %Clear SR400
vider_scrap_compteur
%ibsta=gpib('clr', SR400); %initialiser le discriminateur/compteur de photons - SR400
disp('     -----------------------------------------')
disp('     Status discriminateur-compteur de photons');
status_check(ibsta);
disp('     -----------------------------------------')
%check_status(ibsta);
[spr,ibsta]=gpib('rsp',SR400);
%le 5ieme parametre est le time-out
%0:disabled
%1:10micro s
%2:30micro s
%3:100micro s
%4:300micro s
%5:1ms
%6:3ms
%7:10ms
%8:30ms
%9:100ms
%10:300ms
%11:1s
%12:3s
%13:10s
%14:30s
%15:100s
%16:300s
%17:1000s

function vider_scrap_compteur
%CETTE fonction SERT A ENLEVER LA SCRAP DU COMPTEUR
%A condition que la valeur de la scrap ne soit pas 1.486
global SR400
go=1;
n_bidon=0;
impair = 0 ; pair = 1;
while go
    gpib('wrt',SR400,'ST9')
    gpib('wrt',SR400,'TL 1.486')
    %lit sur le Trig Level
    gpib('wrt',SR400,'TL')
    test = str2num(gpib('rd', SR400));
    if test~= 1.486    % si test ~= 1.486, c'est qu'il y a des donnees (de la scrap)
        n_bidon=n_bidon+1;
        enleve = str2num(gpib('rd', SR400));%sur dans le SR400.
        if enleve == 1.486
            impair = 1; pair=0;
        end
        disp('****   Scrap enlevee du SR400    ****');
    else
        go=0;
    end    
end
switch pair
case 1
    for i=1:n_bidon
        enleve = gpib('rd', SR400);
    end
case 0
    for i=1:n_bidon-1
        enleve = gpib('rd', SR400);
    end
end
gpib('wrt',SR400,'RC9')

function attendre_compteur
%Attend que la mesure soit terminee
global SR400
while ( bitand(bin2dec(sr400('SS')), 4)  == 0  )
    pause(0.1)
end
