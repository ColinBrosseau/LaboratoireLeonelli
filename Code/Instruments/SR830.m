function varargout = sr830(fonction,varargin)
%   varargout = sr830(fonction,varargin)
%
%fonction de controle du lock-in SR830
%
%Les parametre entre {} sont optionnels.
%Il n'y a aucune distinction majuscules-minuscules
%
% fonction
%   initialise  
%               Initialise la communication par le port GPIB
%               sr830('initialise')
%   MESURE
%               Moyenne pendant un certain temps et retourne la valeur moyennee sur un ou les deux canaux
%               [canal_1,canal2] = sr830('mesure',temps_de_la_mesure_en_secondes) 
%               canal = sr830('mesure',temps_de_la_mesure_en_secondes,canal) 
%                canal
%                 '1'
%                 '2'
%   LIRE_CANAL
%               Lit les donneees contenues dans le buffer du canal specifie et retourne la moyenne
%               valeur_du_canal = sr830('lire_canal',canal);
%                canal
%                 '1'
%                 '2'
%   VIDER_MEMOIRE
%               Efface toutes les donnees contenues dans les buffers
%               sr830('vider_memoire');
%   DEMARRER_MESURE
%               Commence une mesure (acquisition des donnees)
%               sr830('demarrer_mesure');
%   ARRETER_MESURE
%               Met la mesure en pause (acquisition des donnees)
%               sr830('arreter_mesure');
%   NOMBRE_DE_POINTS
%               Nombre de points presents dans le buffer
%   SENSIBILITE ou ECHELLE
%               Echelle du SR830
%                (voir sens)
%   CONSTANTE_DE_TEMPS        
%               Constante de temps
%                (voir OFLT)
%   ENTREE
%               Type de source a l'entree (voltmetre ou amperemetre)
%                (voir isrc)
%   PHASE
%               Phase du SR830 p/r a la reference
%                (voir phas)
%   ECHANTILLONAGE
%               Frequence d'echantillonage par le SR830
%                (voir srat)
%   INTERFACE
%               Type d'interface (GPIB ou RS232)
%                (voir outx)
%   agan
%               Active la recherche automatique du gain 
%                sr830('agan')
%   aoff
%               Met automatiquement le 'offset' a zero
%                sr830('aoff',canal)
%                 canal
%                  'X'
%                  'Y'
%                  'R'
%   aphs            
%               Active la recherche automatique de la phase
%                sr830('aphs')
%   arsv
%               Active la recherche automatique de la reserve
%                sr830('arsv')
%   fmod    
%               Reference source
%               source = sr830('fmod',{source})
%                source
%                 'external'
%                 'internal'
%   freq
%               Frequence de fonctionnement
%               freq = sr830('freq',{freq})
%                0.001 <= freq (Hz) <= 102000
%   harm
%               Detection des harmoniques
%               harm = sr830('harm',{harm})
%                1 <= harm <= 19999
%   icpl        
%               Couplage de l'entree
%               couplage_entree = sr830('icpl',{couplage_entree})
%                couplage_entree
%                 'AC'
%                 'DC'
%   ignd        
%               Couplage a la Terre de l'entree
%               mise_terre = sr830('ignd',{mise_terre})
%                mise_terre
%                 'float'
%                 'ground'
%   ilin        
%               Filtre notch de l'entree
%               filtre_notch = sr830('ilin',{filtre_notch})
%                filtre_notch
%                 'no filter'
%                 'line'
%                 '2*line'
%                 'both'
%   isrc    
%               Configuration de l'entree
%               entree = sr830('isrc',{entree})
%                entree
%                 'A'
%                 'A-B'
%                 'I 10^6'
%                 'I 10^8'
%   locl
%               Controle la possibilite de commander le SR830 manuellement
%               mode = sr830('locl',{mode})
%                 'Local'           Commandes GPIB + manuelles possibles
%                 'Remote'          Commandes GPIB seulement + bouton LOCAL
%                 'Local Lockout'   Commandes GPIB seulement
%   oflt        
%               Constante de temps
%               constante_temps = sr830('oflt',{constante_temps})
%                   constante
%                    '10 us'        '1 s'
%                    '30 us'        '3 s'
%                    '100 us'       '10 s'
%                    '300 us'       '30 s'
%                    '1 ms'         '100 s'
%                    '3 ms'         '300 s'
%                    '10 ms'        '1 ks'
%                    '30 ms'        '3 ks'
%                    '100 ms'       '10 ks'
%                    '300 ms'       '30 ks'
%   ofsl            
%               low pass filter slope
%               filter_slope = sr830('ofsl',{filter_slope})
%                filter_slope
%                 '6 dB'
%                 '12 dB'
%                 '18 dB'
%                 '24 dB'
%   outx
%               Ajuste la nature de l'interface.
%               Cette commande doit imperativement etre envoyee avant toute commande de lecture.
%               interface = sr830('outx',interface})
%                interface
%                 'RS232'
%                 'GPIB'
%               
%   ovrm
%               Determine l'acces aux controles manuels
%               sr830('ovrm',mode)
%                mode
%                 'inactif' controles deactives
%                 'actif'   controles possibles
%   paus        
%               Met la mesure (stoquage des donnees) en attente
%               sr830('paus')
%   phas        
%               Phase du lock-n p/r a la reference
%               phase = sr830('phas',{phase})
%                -360.00 <= phase (degres) <= 729.99
%   rest        
%               Efface toutes les donnees donnees en memoire dans le lock-in
%               sr830('rest')
%   rmod
%               Mode de reserve
%               reserve = sr830('rmod',{reserve})
%                reserve
%                 'high reserve'
%                 'normal'
%                 'low noise'
%   rset
%               Restaure la configuration du SR830 a partir d'une memoire non-volatile
%               sr830('rset',indice)
%                1 <= indice <= 9 
%   rslp    
%               Reference trigger
%               trig = sr830('rslp',{trig})
%                trig
%                 'sine'
%                 'TTL rising'
%                 'TTL falling'
%   send
%               Ajuste le mode de fonctionnement en fin de ' buffer'
%               mode = sr830('send',{mode})
%                mode
%                'Shot'
%                'Loop'
%   sens        
%               Sensibilite (echelle) du lock-in
%               sensibilite = sr830('sens',{sensibilite})
%                   sensibilite
%                    '2 nV/fA'      '50 uV/pA'
%                    '5 nV/fA'      '100 uV/pA'           
%                    '10 nV/fA'     '200 uV/pA'           
%                    '20 nV/fA'     '500 uV/pA'           
%                    '50 nV/fA'     '1 mV/nA'           
%                    '100 nV/fA'    '2 mV/nA'            
%                    '200 nV/fA'    '5 mV/nA'            
%                    '500 nV/fA'    '10 mV/nA'            
%                    '1 uV/pA'      '20 mV/nA'            
%                    '2 uV/pA'      '50 mV/nA'            
%                    '5 uV/pA'      '100 mV/nA'            
%                    '10 uV/pA'     '200 mV/nA' 
%                    '20 uV/pA'     '500 mV/nA'
%                                   '1 V/uA'
%   slvl    
%               Amplitude de la sortie sinus
%               amplitude = sr830('slvl',{amplitude})
%                0.004 <= amplitude (V) <= 5.000
%   spts
%               Lit le nombre de points disponibles dans le 'buffer'
%               N = sr830('spts')
%   srat
%               Frequence d'echantillonage par le lock-in
%               freq = sr830('srat',{freq})
%                freq
%                 '62.5 mHz'    '8 Hz'
%                 '125 mHz'     '16 Hz'
%                 '250 mHz'     '32 Hz'
%                 '500 mHz'     '64 Hz'
%                 '1 Hz'        '128 Hz'
%                 '2 hz'        '256 Hz'
%                 '4 Hz'        '512 Hz'
%                               'Trigger'             
%   sset
%               Sauvegarde la configuration du SR830 dans une memoire non-volatile
%               sr830('sset',indice)
%                1 <= indice <= 9 
%   strt        
%               Demarre la mesure (stoquage des donnees) (ou la redemarre si elle etait sur PAUSE)
%               sr830('strt')
%   sync        
%               syncrhonisite du filtre
%               sync = sr830('sync',{sync})
%                sync
%                 'off'
%                 'on'
%   trcl
%               Lit les points enregistres dans le 'buffer'
%               points = sr830('trcl',buffer,Debut,N)
%                buffer
%                 '1'   Canal de gauche
%                 '2'   Canal de droite
%                0 <= Debut <= Nombre_de_donneees (voir SPTS)
%                 N : Nombre de donnees a lire (Ne pas depasser la valeur donnee par SPTS)
%   trig
%               Envoit un signal de trig
%               sr830('trig')
%   *rst
%               Reinitialise le SR830 a ses configurations par defaut
%               sr830('*rst')             
%   *idn
%               Demande l'identifiant de l'appareil
%               identifiant = sr830('*idn')
%               
%   *cls
%               Efface tous les registres d'etat GPIB
%                sr830('*cls')
%Fonctions pas (encore) implementeees
%   DDEF
%   FPOP
%   OEXP
%   AOFF
%   OAUX
%   AUXV
%   outp
%   outr
%   snap
%   oaux
%   trca
%   trcb
%   fast
%   strd
%   ovrm
%   *ese
%   *esr
%   *sre
%   *stb
%   *psc
%   erre
%   errs
%   liae
%   lias
%   kclk
%   alrm
%   tstr
% 
%   ENREGISTRE_CONFIGURATION
%               Sauvegarde l'etat du SR830 dans un fichier (*.m)
%               sr830('ENREGISTRE_CONFIGURATION',fichier)
%Colin Fevrier 2006

global SR830
global SR830_PRESENT
ADRESSE_GPIB_DU_SR830 = 8;

if isempty(SR830)
    initialise_SR830(ADRESSE_GPIB_DU_SR830) %l'addresse par defaut est 23
end

%tables de conversion des fonctions speciales
switch upper(fonction)
case 'SENS'    
    table = {'2 nV/fA';'5 nV/fA';'10 nV/fA';'20 nV/fA';'50 nV/fA';'100 nV/fA';'200 nV/fA';'500 nV/fA';'1 uV/pA';'2 uV/pA';'5 uV/pA';'10 uV/pA';'20 uV/pA';'50 uV/pA';'100 uV/pA';'200 uV/pA';'500 uV/pA';'1 mV/pA';'2 mV/pA';'5 mV/pA';'10 mV/pA';'20 mV/pA';'50 mV/pA';'100 mV/pA';'200 mV/pA';'500 mV/pA';'1 V/uA'};
case 'OFLT'
    table = {'10 us';'30 us';'100 us';'300 us';'1 ms';'3 ms';'10 ms';'30 ms';'100 ms';'300 ms';'1 s';'3 s';'10 s';'30 s';'100 s';'300 s';'1 ks';'3 ks';'10 ks';'30 ks';};
case 'FMOD'
    table = {'external';'internal'};
case 'RSLP'
    table = {'sine';'TTL rising';'TTL falling'};
case 'ISRC'
    table = {'A';'A-B';'I 10^6';'I 10^8';};
case 'IGND'
    table = {'float','ground'};
case 'ICPL'
    table = {'AC','DC'};
case 'ILIN'
    table = {'no filter';'line';'2*line';'both'};
case 'RMOD'
    table = {'high reserve','normal','low noise'};
case 'OFSL'
    table = {'6 dB';'12 dB';'18 dB';'24 dB';};
case 'SYNC'
    table = {'off','on'};
case 'OUTX'
    table = {'RS232','GPIB'};
case 'OVRM'
    table = {'inactif','actif'};
case 'SRAT'
    table = {'62.5 mHz','125 mHz','250 mHz','500 mHz','1 Hz','2 hz','4 Hz','8 Hz','16 Hz','32 Hz','64 Hz','128 Hz','256 Hz','512 Hz','Trigger'};
case 'SEND'
    table = {'Shot','Loop'};
case 'LOCL'
    table = {'Local','Remote','Local Lockout'};
case 'AOFF'
    table = {'X','Y','R'};
case 'DDEF'
    table_j = {'X','R','X Noise','Aux In1','Aux In2';'Y','Theta','Y Noise','Aux In3','Aux In4'};
    table_k = {'none','Aux In1','Aux In2';'none','Aux In3','Aux In4'};
end

switch upper(fonction)
case {'INITIALISE'}
    global SR830
    SR830 = [];
    if nargin > 1
        nouvel_argument = varargin{1};
    else
        nouvel_argument = ADRESSE_GPIB_DU_SR830;
    end
    disp('     Initialisation de l`amplificateur synchrone SR830')
    initialise_SR830(nouvel_argument)
case {'STRT','PAUS','REST','AGAN','ARSV','APHS','TRIG','*RST','*CLS'}
    %fonction  0 parametre
    %          0(1) sortie  
    sta = gpib('wrt', SR830, [fonction ' ' char(10)]);
    check_error(sta)
    varargout{1} = 'OK';
case {'PHAS','FREQ','SLVL','HARM'}
    %fonction  0-1 parametre
    %          1 sortie 
    if nargin > 1 %controle
        nouvel_argument = varargin{1};
        if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
        sta = gpib('wrt', SR830, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr830(fonction);
    else %lecture
        sta = gpib('wrt', SR830, [fonction '? ' char(10)]);
        out = gpib('rd', SR830);
        if double(out(end)) == 10; out = out(1:end-1); end
        if double(out(end)) == 13; out = out(1:end-1); end
        varargout{1} = out;
        check_error(sta)
    end   
case {'SPTS','*IDN'}
    %fonction  0 parametre
    %          1 sortie 
    sta = gpib('wrt', SR830, [fonction '? ' char(10)]);
    out = gpib('rd', SR830);
    if double(out(end)) == 10; out = out(1:end-1); end
    if double(out(end)) == 13; out = out(1:end-1); end
    varargout{1} = out;
    check_error(sta)
case {'SSET','RSET'}
    %fonction  1 parametre indice
    %          0(1) sortie 
    nouvel_argument = varargin{1};
    if isnumeric(nouvel_argument); nouvel_argument=num2str(nouvel_argument); end       
    sta = gpib('wrt', SR830, [fonction ' ' nouvel_argument char(10)]);
    varargout{1} = 'OK';
case {'SENS','OFLT','FMOD','RSLP','ISRC','IGND','ICPL','ILIN','RMOD','OFSL','SYNC','OUTX','OVRM','SRAT','SEND','LOCL'}   
    %fonction  0-1 parametre
    %          1 sortie chaine de caractere
    %fonctions speciales avec table de conversion
    if nargin > 1 %controle
        table = upper(table);
        nouvel_argument = upper(varargin{1});
        if ~isnumeric(nouvel_argument) %on a fourni une chaine de caractere au lieu d'un nombre
            nouvel_argument = num2str(strmatch(nouvel_argument,table,'exact') - 1);
        else
            nouvel_argument = num2str(nouvel_argument);
        end
        sta = gpib('wrt', SR830, [fonction ' ' nouvel_argument char(10)]);
        varargout{1} = sr830(fonction);
    else %lecture
        sta = gpib('wrt', SR830, [fonction '? ' char(10)]);
        out = str2num(gpib('rd', SR830));
        varargout{1} = table{out+1};
        check_error(sta)
    end   
case {'AOFF'}   
    %fonction  1 parametre
    %          0(1) sortie 
    %fonctions speciales avec table de conversion
    table = upper(table);
    nouvel_argument = upper(varargin{1});
    nouvel_argument = num2str(strmatch(nouvel_argument,table,'exact') - 1);
    sta = gpib('wrt', SR830, [fonction ' ' nouvel_argument char(10)]);
    varargout{1} = 'OK';
case 'DDEF'
    %fonction  0-1 parametre
    %          1 sortie chaine de caractere
    %fonction speciale avec table de conversion
    if nargin > 2 %controle
        table_j = upper(table_j);
        table_k = upper(table_k);
        i = varargin{1}; if isnumeric(i); i=num2str(i); end       
        j = upper(varargin{2});
        j = num2str(strmatch(j,table_j(str2num(i),:),'exact') - 1);
        k = upper(varargin{3});
        k = num2str(strmatch(k,table_k(str2num(i),:),'exact') - 1);      
        sta = gpib('wrt', SR830, [fonction ' ' i ',' j ',' k char(10)]);
        varargout{1} = sr830(fonction,i);
    else %lecture
        i = varargin{1}; if isnumeric(i); i=num2str(i); end       
        sta = gpib('wrt', SR830, [fonction '? ' i ' ' char(10)]);
        out = str2num(gpib('rd', SR830));
        a = table_j(str2num(i),out(1)+1); 
        b = table_k(str2num(i),out(2)+1); 
        varargout{1} = [i ',' a{1} ',' b{1}];
        check_error(sta)
    end   
case 'TRCL'
    canal = varargin{1}; if isnumeric(canal); canal=num2str(canal); end       
    Debut = varargin{2}; if isnumeric(Debut); Debut=num2str(Debut); end       
    N = varargin{3}; if isnumeric(N); N=num2str(N); end       
    sta = gpib('wrt', SR830, [fonction '? ' canal ',' Debut ',' N ' ' char(10)]);
    [temp, IBSTA] = gpib( 'rdi', SR830, 2*str2num(N) );
    for i=1:str2num(N)
        mantise(i) = temp(1+(i-1)*2);
        exp(i) = temp(2+(i-1)*2) - 124;
    end
    varargout{1} = mantise .* 2 .^exp;
    check_error(sta)
case 'LIRE_CANAL'
    %lit les donneees contenues dans le buffer du canal specifie et retourne la moyenne
    canal = varargin{1}; if isnumeric(canal); canal=num2str(canal); end       
    N = sr830('spts');
    out = sr830('trcl',canal,0,N);
    varargout{1} = mean(out);
case 'LIRE_CANAUX'
    %lit les donneees contenues dans le buffer des deux canaux et retourne la moyenne
    N = sr830('spts');
    varargout{1} = mean(sr830('trcl','1',0,N));
    varargout{2} = mean(sr830('trcl','2',0,N));
case 'MESURE'
    %moyenne pendant un certain temps et retourne la valeur moyennee sur un ou les deux canaux
    %sr830('mesure',temps_de_la_mesure,{canal}) % si canal (1 ou 2) est absent,  la fonction lit sur les deux canaux
    temps_de_la_mesure = varargin{1};
    sr830('ARRETER_MESURE');
    sr830('VIDER_MEMOIRE');
    sr830('DEMARRER_MESURE');
    pause(temps_de_la_mesure)
    sr830('ARRETER_MESURE');
    if nargin > 2 %mesure sur un seul canal
        canal_a_lire = varargin{2};
        varargout{1} = sr830('lire_canal',canal_a_lire);
    else
        [a,b] = sr830('lire_canaux');
        varargout{1} = a;
        varargout{2} = b;
    end
    sr830('VIDER_MEMOIRE');
case 'ENREGISTRE_CONFIGURATION'
    if nargin==1 
        fichier = input('Nom du fichier de sauvegarde: ','s');
    else
        fichier = varargin{1};
    end
    if ~strcmp(fichier(end-1:end),'.m')
        fichier = [fichier '.m'];
    end
    fid = fopen(fichier,'w');
    table = {'PHASE','SENSIBILITE','CONSTANTE_DE_TEMPS','ENTREE','ECHANTILLONAGE','INTERFACE','SOURCE_REFERENCE','MODE_REFERENCE','FREQUENCE_INTERNE','HARMONIQUE','AMPLITUDE_SORTIE_SINUS','ENTREE','COUPLAGE_TERRE_ENTREE','COUPLAGE_ACDC_ENTREE','FILTRE_NOTCH','RESERVE','LOW_PASS_FILTER_SLOPE','FILTRE_SYNCHRONE','END_OF_BUFFER_MODE'};
    for i=1:length(table)
        ['sr830('  ''''  table{i} ''''  ',''%s'');\n']
        disp(feval('sr830',table{i}))
        fprintf(fid,['sr830('  ''''  table{i} ''''  ',''%s'');\n'],feval('sr830',table{i}));
    end
    out = fclose(fid);
    switch out
    case 0
        disp('Configuration du SR830 enregistree ')
        disp(['  avec succes dans le fichier: ' fichier])
    case -1
        disp(['Erreur dans l''enregistrement de la configuration du SR400' ])
    end    
    
otherwise 
    %fonctions alias
    switch upper(fonction)
    case 'ARRETER_MESURE' %met la mesure en pause (acquisition des donnees)
        chaine = 'paus';
    case 'VIDER_MEMOIRE'  %efface toutes les donnees contenues dans les buffers
        chaine = 'rest';
    case 'DEMARRER_MESURE'%commence une mesure (acquisition des donnees)
        chaine = 'strt';
    case 'NOMBRE_DE_POINTS'
        chaine = 'spts';
    case {'SENSIBILITE','ECHELLE'}
        chaine = 'sens';
    case 'CONSTANTE_DE_TEMPS'
        chaine = 'OFLT';
    case 'ENTREE'
        chaine = 'isrc';
    case 'PHASE'
        chaine = 'phas';
    case 'INTERFACE'
        chaine = 'outx';
    case 'ECHANTILLONAGE'
        chaine = 'srat';
    case 'SOURCE_REFERENCE'
        chaine = 'fmod';
    case 'MODE_REFERENCE'
        chaine = 'rslp';    
    case 'FREQUENCE_INTERNE'
        chaine = 'freq';
    case 'HARMONIQUE'
        chaine = 'harm';
    case 'AMPLITUDE_SORTIE_SINUS'
        chaine = 'slvl';
    case 'COUPLAGE_TERRE_ENTREE'
        chaine = 'ignd';        
    case 'COUPLAGE_ACDC_ENTREE'
        chaine = 'icpl';        
    case 'FILTRE_NOTCH'
        chaine = 'ilin';
    case 'RESERVE'
        chaine = 'rmod';
    case 'LOW_PASS_FILTER_SLOPE'
        chaine = 'ofsl';
    case 'FILTRE_SYNCHRONE'
        chaine = 'sync';
    case 'END_OF_BUFFER_MODE'
        chaine = 'send';
    end
    varargout = {sr830(chaine,varargin{:})};
%     temp = sr830(chaine,varargin{:})
%     length(temp)
%     for i=1:length(temp)
%         i
%         varargout{i} = temp(i);
%     end
%     if nargout > 0; varargout{1:max(nargout,1)} = sr830(chaine,varargin{:});
%     else sr830(chaine,varargin);
%     end
end



%****************************************************************
function initialise_SR830(addresse)
%initialise_SR830(addresse)
%initialise lock-in SR830
global ud0
global SR830
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
SR830 = gpib('dev', 0, addresse, 0, 13, 1, 0);
[spr,ibsta]=gpib('rsp',SR830);
disp('-----------------------------------------')
disp('Status lock-in SR830');
status_check(ibsta);
disp('-----------------------------------------')
disp(' ');
