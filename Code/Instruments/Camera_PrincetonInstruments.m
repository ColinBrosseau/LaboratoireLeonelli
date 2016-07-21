function varargout = Camera_PrincetonInstruments(fonction, varargin)
%   varargout = Camera_PrincetonInstruments(fonction, varargin)
%
%Fonction de controle d'une caméra Princeton Instruments
%
%Fonctions principales:
%
% Camera_PrincetonInstruments('CONFIG_INITIAL')
%   Place la caméra dans une configuration de référence:
%   '100 kHz', gain=1, temp_setpoint=-70, LOGIC_OUTPUT=shutter
%
% Camera_PrincetonInstruments('enregistre_configuration')
%   Crée un fichier .m permettant de replacer la Camera exactement dans le
%   meme état que l'état actuel
%
% Camera_PrincetonInstruments('FERMER')
%   Termine la communication avec la caméra
%
% Camera_PrincetonInstruments('GAIN', gain)
%   Lit ou écrit le gain de la camera
%   gain (optionnel) = 1, 2 ou 3
%
% Camera_PrincetonInstruments('GET_PARAMETER', Nom_parametre)
%   Lit la valeur d'un parametre de la camera
%   Nom_parametre (string): Voir me manuel de référence pour le nom des
%   parametres possibles
%
% Camera_PrincetonInstruments('GET_PARAMETER_ALL', Nom_parametre)
%   Exactement comme Camera_PrincetonInstruments('GET_PARAMETER', Nom_parametre) mais affiche plus
%   d'information à l'écran.
%
% Camera_PrincetonInstruments('IMAGE', PARAM)
%   fait une acquisition. Retourne une image (intensité du chaque pixel)
%   PARAM  (struct)
%       PARAM.t_acc (optionnel)
%           temps d'acquisition en seconde(s)
%       PARAM.n_acc (optionnel)
%           nombre d'images à prendre
%       PARAM.mode (optionnel)
%           exposure mode
%       PARAM.window (optionnel)
%           Région (sur la camera) à mesurer
%           Si ce parametres n'est pas spécifié. Utilise l'ensemble du
%           détecteur sauf les premiers pixels "en haut" (voir la définition de la fonction 'image' plus bas)
%           PARAM.window.s1
%               debut de la plage (en x)
%           PARAM.window.s2
%               fin de la plage (en x)
%           PARAM.window.sbin
%               nombre relatif au binning (en x)
%           PARAM.window.p1
%               debut de la plage (en y)
%           PARAM.window.p2
%               fin de la plage (en y)
%           PARAM.window.pbin
%               nombre relatif au binning (en y)
%           x represente (en general) la longueur d'onde
%           y représente l'axe vertival (sans signification physique)
%           s relatif a x
%           p relatif a y
%           Exemple: 
%               PARAM.window.s1=0; PARAM.window.s2=1023; PARAM.window.sbin=1; 
%                   Les 1024 pixels dans la direction x sont considérés séparément.
%           Exemple: 
%               PARAM.window.p1=10; PARAM.window.p2=255; PARAM.window.pbin=246; 
%                   Les 256 pixels dans la direction y sont considérés comme un seul et meme pixel.
%           Note importante : Pixis eviter les premier 5-7 premiers pixels "en haut"
%               car ils sont toujours "saturés". On devrait mettre
%               PARAM.window.p1 >= 10
%
% Camera_PrincetonInstruments('initialise', camIndex)
%   Initialise la communication avec la caméra
%   camIndex (entier: 0, 1, 2, 3 ...)
%       utile lorsqu'on utilise plus d'une camera avec Winspec
%       permet de specifier laquelle on utilise
%
% Camera_PrincetonInstruments('live_image', PARAM)
%   Fait des acquisitions d'images les unes apres les autres. Affiche le résultat en continu
%   PARAM  (struct)
%       PARAM.t_acc (optionnel)
%           temps d'acquisition en seconde(s)
%   Note: PARAM peu contenir d'autres parametres (voir Camera_PrincetonInstruments('image', PARAM))
%
% [x,y] = Camera_PrincetonInstruments('PIXEL_DIMENSION')
%   Lit la distance entre les pixels ('horizontal' et 'vertical')
%
% Camera_PrincetonInstruments('live_spectre', PARAM)
%   Fait des acquisitions de spectre les unes apres les autres. Affiche le résultat en continu
%   PARAM  (struct)
%       PARAM.t_acc (optionnel)
%           temps d'acquisition en seconde(s)
%   Note: PARAM peu contenir d'autres parametres (voir Camera_PrincetonInstruments('SPECTRE', PARAM))
%
% Camera_PrincetonInstruments('PL_GET_PARAM', Nom_parametre)
%   Exactement comme Camera_PrincetonInstruments('GET_PARAMETER', Nom_parametre)
%
% Camera_PrincetonInstruments('PL_SET_PARAM', Nom_parametre, Valeur_parametre)
%   Écrit la valeur d'un parametre de la camera
%   Nom_parametre (string): Voir me manuel de référence pour le nom des
%   parametres possibles
%   Valeur_parametre (string) ou entier: Voir me manuel de référence
%
% Camera_PrincetonInstruments('SHUTTER', shutter)
%   Ouvre ou ferme le shutter mécanique
%   shutter = 'ouvert' ou 'ferme'
%
% Camera_PrincetonInstruments('SPECTRE', PARAM)
%   Prend une mesure et retourne le spectre (binning par longueur d'onde)
%   PARAM  (struct)
%       Tous les même champs que pour la fonction Camera_PrincetonInstruments('IMAGE', PARAM)
%       Peu contenir d'autres parametres (voir Camera_PrincetonInstruments('image', PARAM))
%       PARAM.plage_binning (optionnel)
%           [vecteur]
%           Plage utilisée pour faire le binning (logiciel) pour calculer le spectre.
%
% Camera_PrincetonInstruments('SPEED', speed)
%   Écrit la vitesse de l'ADC de la camera
%   speed = '100 kHz' ou '2 MHz'
%
% Camera_PrincetonInstruments('TEMP')
%   Lit la température de la caméra
%
% Camera_PrincetonInstruments('TEMP_SETPOINT', temperature_cible)
%   Lit ou écrit la température cible de la caméra
%   température cible (optionnel)
%

%
%2 decembre 2008
%   Colin
%   basée sur trivista.m
%   ajoute les fonctions 'INITIALISE', 'INITIALISE_ACQUISITION' et
%   'ACQUIRE' et 'FERMER', 'SHUTTER'
%   à partir des fonctions crées initialement pas Mathieu Perrin
%3 decembre 2008
%   Colin
%   Ajout des fonctions extrèmement importantes 'GET_PARAMETER' et
%   'SET_PARAMETER' et toutes les autres
%28 fevrier 2011
%   Colin
%   Attend moins longtemps avant de verifier si la mesure est terminée
%   Légère modification a la condition qui initialise automatiquement la
%   camera si la librairie n'est pas chargee en memoire
%9 dec 2015
%   Colin
%   Ajout de 'chip_name' et 'DIMENSION_DETECTEUR'
%20 juillet 2016
%   Colin
%   Ajout 'pixel_dimension'

Librairie_Camera = 'Pvcam32';

%variable qui représente la camera
global Camera_PI

%Camera_PI.handle
%   handle de la camera
%Camera_PI.bufferSize
%   taille totale en octet pour stocker les images
%   = nImages*xsize*ysize*sizeof(uint16)

if ~libisloaded(Librairie_Camera) && ~strcmp(upper(fonction), 'FERMER') %|| isempty(Camera_PI)
    disp(['La bibliotheque ' Librairie_Camera '.dll n''a pas ete chargee en memoire' ]);
    loadlibrary (Librairie_Camera, 'pixis.h');
    
    Camera_PrincetonInstruments('INITIALISE');
end

if nargin>1
    PARAM = varargin{1};
else
    PARAM = struct;
end

switch upper(fonction)
    case 'INITIALISE'
        %initialise la communication, charge la librairie
        %Initialisation de la communication avec la PDA InGaAs depuis une
        %interface graphique (ou pas).(PDA InGaAs... :s)
        %
        %Camera_PI (struct)
        %   contient les parametres de la camera
        %
        %   Camera_PI.PVCAM
        %   Camera_PI.camName
        %       nom de la camera
        %   Camera_PI.xsize
        %       nombre de pixels en x
        %   Camera_PI.ysize
        %       nombre de pixels en y
        %
        if nargin>1
            camIndex = varargin{1};
        else
            camIndex = 0;
        end
        
        Camera_PI.PVCAM = PVCAMConstants; % on sauve les constantes de PVCAMConstants dans
        
        % Ferme une éventuelle connexion à la camera
        %   Note: on ne peut pas utiliser simplement Camera_PrincetonInstruments('FERMER'); 
        if libisloaded(Librairie_Camera)
            disp(['     Retire la bibliotheque ' Librairie_Camera '.dll de la memoire']);
            %dump = calllib(Librairie_Camera, 'pl_cam_close', Camera_PI.handle); 
            dump = calllib(Librairie_Camera, 'pl_pvcam_uninit');
            unloadlibrary(Librairie_Camera);
        end
        
        loadlibrary(Librairie_Camera, 'pixis.h');
        calllib(Librairie_Camera, 'pl_pvcam_init');%on doit appeler 'pl_pvcam_init' avant toute autre fonction de Librairie_Camera (p. 45 manuel)
        
        Camera_PI.camName = blanks(Camera_PI.PVCAM.CCD_NAME_LEN);
        [dump Camera_PI.camName] = calllib(Librairie_Camera, 'pl_cam_get_name', camIndex, Camera_PI.camName); errtest(dump);

        %disp(['     Initialisation de la camera : ' Camera_PI.camName]);

        [dump Camera_PI.camName Camera_PI.handle] = calllib(Librairie_Camera, 'pl_cam_open', Camera_PI.camName, 0, Camera_PI.PVCAM.OPEN_EXCLUSIVE);
        errtest(dump); 
        
        camName = Camera_PrincetonInstruments('CHIP_NAME');
        switch camName
            case 'EEV  256x1024OE'
                Camera_PI.camName = 'Pixis';
            case 'InGaAs    1x1024' 
                Camera_PI.camName = 'InGaAs';
            otherwise
            Camera_PI.camName = blanks(Camera_PI.PVCAM.CCD_NAME_LEN);
            [dump Camera_PI.camName] = calllib(Librairie_Camera, 'pl_cam_get_name', camIndex, Camera_PI.camName); errtest(dump);
        end
        disp(['     Camera initialisee: ' Camera_PI.camName]);

        [Camera_PI.xsize, Camera_PI.ysize] = Camera_PrincetonInstruments('DIMENSION_DETECTEUR');

        disp('     set: Parametres par defaut de la camera')
        Camera_PrincetonInstruments('CONFIG_INITIAL')

    case 'CONFIG_INITIAL'
        %disp(Parametres par défaut de la caméra)
        %Il est important de ne pas mettre cette fonction dans 'initialise'
        %pour permetre de régler la camera et d'ouvrir ensuite une fonction
        %(quelconque) qui re-initialise la camera sans perdre les réglages.
        Camera_PrincetonInstruments('speed', '100 khz');
        Camera_PrincetonInstruments('temp_setpoint', -70);
        Camera_PrincetonInstruments('gain', 1);
        Camera_PrincetonInstruments('LOGIC_OUTPUT', 'shutter');
        switch Camera_PI.camName
            case 'Pixis'
                Camera_PrincetonInstruments('temp_setpoint', -70);
            case 'InGaAs'
                Camera_PrincetonInstruments('temp_setpoint', -100);
        end
        
    case 'CHIP_NAME'
        varargout{1} = Camera_PrincetonInstruments('get_parameter', 'PARAM_CHIP_NAME');
     
    case 'DIMENSION_DETECTEUR'
        varargout{1} = Camera_PrincetonInstruments('get_parameter', 'PARAM_SER_SIZE');
        varargout{2} = Camera_PrincetonInstruments('get_parameter', 'PARAM_PAR_SIZE');
        
    case 'NOM'
        %retourne le nom de la camera
        varargout{1} = Camera_PI.camName;
        
    case 'SPECTRE'
        %disp('SPECTRE')
        %Camera_PI
        if ~isfield(PARAM, 'window')
            PARAM.window = struct;
        end
        if ~isfield(PARAM.window, 's1') %horizontal (energy, wavelength)
            PARAM.window.s1 = 0;
        end
        if ~isfield(PARAM.window, 's2')
            PARAM.window.s2 = Camera_PI.xsize - 1;
        end
        if ~isfield(PARAM.window, 'sbin')
            PARAM.window.sbin = 1;
        end
        if ~isfield(PARAM.window, 'p1') %vertical
            PARAM.window.p1 = 10;
        end
        if ~isfield(PARAM.window, 'p2')
            PARAM.window.p2 = Camera_PI.ysize - 5;
        end
        if PARAM.window.s1 < 0
            PARAM.window.s1 = 0;
        end
        if PARAM.window.s1 > Camera_PI.xsize
            PARAM.window.s1 = Camera_PI.xsize - 1;
        end
        if PARAM.window.s2 < PARAM.window.s1
            PARAM.window.s2 = PARAM.window.s1;
        end
        if PARAM.window.s2 > Camera_PI.xsize - 1
            PARAM.window.s2 = Camera_PI.xsize - 1;
        end
        if PARAM.window.p1 < 0
            PARAM.window.p1 = 0;
        end
        if PARAM.window.p1 > Camera_PI.ysize
            PARAM.window.p1 = Camera_PI.ysize - 1;
        end
        if PARAM.window.p2 < PARAM.window.p1
            PARAM.window.p2 = PARAM.window.p1;
        end
        if PARAM.window.p2 > Camera_PI.ysize - 1
            PARAM.window.p2 = Camera_PI.ysize - 1;
        end
        %sum all vertical pixel as they are one
        PARAM.window.pbin = PARAM.window.p2 - PARAM.window.p1 + 1;
        %
        %         if ~isfield(PARAM, 'plage_binning')
        %             PARAM.plage_binning = [1:256];
        %         end
        %         data = Camera_PrincetonInstruments('IMAGE', PARAM);
        %         varargout{1} = sum(data(PARAM.plage_binning, :), 1)';
        %PARAM.window
        varargout{1} = Camera_PrincetonInstruments('IMAGE', PARAM);

    case 'IMAGE'
        if ~isfield(PARAM, 't_acc')
            PARAM.t_acc = 1;
        end
        PARAM.t_acc = PARAM.t_acc*1000; %conversion en ms
        if ~isfield(PARAM, 'n_acc')
            PARAM.n_acc = 1;
        end
        if ~isfield(PARAM, 'mode')
            PARAM.mode = Camera_PI.PVCAM.VARIABLE_TIMED_MODE;
        end
        if ~isfield(PARAM, 'window')
            PARAM.window = struct; end
        if ~isfield(PARAM.window, 's1')
            PARAM.window.s1 = 0; end
        if ~isfield(PARAM.window, 's2')
            PARAM.window.s2 = Camera_PI.xsize - 1; end
        if ~isfield(PARAM.window, 'sbin')
            PARAM.window.sbin = 1; end
        if ~isfield(PARAM.window, 'p1')
            PARAM.window.p1 = 10; end
        if ~isfield(PARAM.window, 'p2')
            PARAM.window.p2 = Camera_PI.ysize - 1; end
        if ~isfield(PARAM.window, 'pbin')
            PARAM.window.pbin = 1; end
        if PARAM.window.s1 < 0
            PARAM.window.s1 = 0; end
        if PARAM.window.s2 > Camera_PI.xsize - 1
            PARAM.window.s2 = Camera_PI.xsize - 1;
        end
        if PARAM.window.p1 < 0
            PARAM.window.p1 = 0;
        end
        if PARAM.window.p2 > Camera_PI.ysize - 1
            PARAM.window.p2 = Camera_PI.ysize - 1;
        end
        
        %if needed, correct the upper bound (so we have an integer number
        %of pixels in a bin
        PARAM.window.s2 = floor((PARAM.window.s2-PARAM.window.s1+1)/PARAM.window.sbin)*PARAM.window.sbin + PARAM.window.s1 - 1;
        PARAM.window.p2 = floor((PARAM.window.p2-PARAM.window.p1+1)/PARAM.window.pbin)*PARAM.window.pbin + PARAM.window.p1 - 1;
    
        %disp(PARAM.t_acc)
        %PARAM.window
        
        xsize = floor((PARAM.window.s2 - PARAM.window.s1 + 1)/PARAM.window.sbin);
        ysize = floor((PARAM.window.p2 - PARAM.window.p1 + 1)/PARAM.window.pbin);

        %PARAM
        %PARAM.window
        
        %prepare la camera
        dump = calllib(Librairie_Camera, 'pl_exp_init_seq'); 
        errtest(dump);
        [dump region Camera_PI.bufferSize] = calllib(Librairie_Camera, 'pl_exp_setup_seq', Camera_PI.handle, PARAM.n_acc, 1, PARAM.window, PARAM.mode, PARAM.t_acc, 0);
        errtest(dump);
        %disp('Camera_PI.bufferSize')
        %Camera_PI.bufferSize
        
        % allocation de la memoire (2=sizeof(uint16))
        buffer = zeros(1, Camera_PI.bufferSize/2, 'uint16');
        bufferp = libpointer('uint16Ptr', buffer);
        
        %demare la mesure
        dump = calllib(Librairie_Camera, 'pl_exp_start_seq', Camera_PI.handle, bufferp); 
        errtest(dump);
        %attend la fin de la mesure
        status = Camera_PI.PVCAM.EXPOSURE_IN_PROGRESS;
        while (status ~= Camera_PI.PVCAM.READOUT_COMPLETE && status ~= Camera_PI.PVCAM.READOUT_FAILED)
            [dump status] = calllib(Librairie_Camera, 'pl_exp_check_status', Camera_PI.handle, status, 0);
            pause(.02)
            
        end
        calllib(Librairie_Camera, 'pl_exp_finish_seq', Camera_PI.handle, bufferp, 0);
        
        % Il faut reshaper le pointeur avant de pouvoir acceder aux donnees
               
        reshape(bufferp, Camera_PI.bufferSize/2/PARAM.n_acc, PARAM.n_acc); % attention, il faut mettre les colonnes en premier
        data = sum(bufferp.Value, 2); %somme sur toutes les mesures
        %met dans la forme d'une matrice (image)
      
        if xsize==1 & ysize==1% Il y a un probleme si on bin pour avoir une seule donnée, facque... ben c'est reglé.
            data=data(1, 1);
        end
        
        %whos
        
        data = (reshape(data, xsize, ysize))';
        varargout{1} = data;

    case 'FERMER'
        %Ferme la commumication avec la camera
        if libisloaded(Librairie_Camera)
            disp(['Retire la bibliotheque ' Librairie_Camera '.dll de la memoire.']);
            dump = calllib(Librairie_Camera, 'pl_cam_close', Camera_PI.handle); errtest(dump);
            dump = calllib(Librairie_Camera, 'pl_pvcam_uninit'); errtest(dump);
            unloadlibrary(Librairie_Camera);
        else
            disp(['Bibliotheque ' Librairie_Camera '.dll déjà retirée de la memoire.'])
        end

    case 'TEMP'
        %lit la température actuelle de la camera (C)
        PARAMETRE = 'PARAM_TEMP';
        Facteur = 100;

        if nargin == 1 %lecture
            varargout{1} = Camera_PrincetonInstruments('get_parameter', PARAMETRE)/Facteur;
        end

    case 'TEMP_SETPOINT'
        %lit/écrit
        %la température du set point (C)
        %
        %Camera_PrincetonInstruments('TEMP_setpoint', temperarure)

        %La multiplication par 100 vient du fait de la représentation
        %interne de la camera
        PARAMETRE = 'PARAM_TEMP_SETPOINT';
        Facteur = 100;

        if nargin == 1 %lecture
            varargout{1} = Camera_PrincetonInstruments('get_parameter', PARAMETRE)/Facteur;
        else  %ecriture
            Valeur = varargin{1}; %temperature voulue
            Camera_PrincetonInstruments('set_parameter', PARAMETRE, Valeur*Facteur)
            varargout{1} = Camera_PrincetonInstruments(fonction);
        end

    case 'GAIN'
        
        %lit/écrit
        %Gain d'amplification du signal du détecteur
        %
        %Camera_PrincetonInstruments('GAIN', 1)
        PARAMETRE = 'PARAM_GAIN_INDEX';
        Facteur = 1;

        if nargin == 1 %lecture
            varargout{1} = Camera_PrincetonInstruments('get_parameter', PARAMETRE)/Facteur;
            
        else  %ecriture
            Valeur = varargin{1}; %gain voulu
            Camera_PrincetonInstruments('set_parameter', PARAMETRE, Valeur*Facteur)
            varargout{1} = Camera_PrincetonInstruments(fonction);
        end

    case 'SPEED'
        %lit/écrit
        %vitesse de lecture de l'ADC
        %
        %Camera_PrincetonInstruments('SPEED', '100 KHZ')
        PARAMETRE = 'PARAM_SPDTAB_INDEX';

        if nargin == 1 %lecture
            Valeur = Camera_PrincetonInstruments('get_parameter', PARAMETRE);
            switch upper(Valeur)
                case 0
                    Valeur = '100 KHZ';
                case 1
                    Valeur = '2 MHZ';
            end
            varargout{1} = Valeur;
        else  %ecriture
            Valeur = varargin{1}; %vitesse voulue
            switch upper(Valeur)
                case '100 KHZ'
                    Valeur = 0;
                case '2 MHZ'
                    Valeur = 1;
            end
            
            Camera_PrincetonInstruments('set_parameter', PARAMETRE, Valeur)
            varargout{1} = Camera_PrincetonInstruments(fonction);
        end

    case 'LOGIC_OUTPUT'
        %lit/écrit
        %ce à quoi correspond la sortie logique
        %
        %Camera_PrincetonInstruments('LOGIC_OUTPUT', 'shutter')
        PARAMETRE = 'PARAM_LOGIC_OUTPUT';

        if nargin == 1 %lecture
            varargout{1} = Camera_PrincetonInstruments('get_parameter', PARAMETRE);
        else  %ecriture
            Valeur = varargin{1}; %vitesse voulue
            switch upper(Valeur)
                case 'NOT SCAN'
                    Valeur = 0;
                case 'SHUTTER'
                    Valeur = 1;
                case 'NOT READY'
                    Valeur = 2;
                case 'LOGIC 0'
                    Valeur = 3;
                case 'LOGIC 1'
                    Valeur = 4;
            end
            Camera_PrincetonInstruments('set_parameter', PARAMETRE, Valeur)
            varargout{1} = Camera_PrincetonInstruments(fonction);
        end
        
    case 'PIXEL_DIMENSION'
        %Lit
        % pixel pitch en x et en y
        varargout{1} = Camera_PrincetonInstruments('GET_PARAMETER', 'PARAM_PIX_SER_DIST');
        varargout{2} = Camera_PrincetonInstruments('GET_PARAMETER', 'PARAM_PIX_PAR_DIST');

    case 'SHUTTER'
        %Camera_PrincetonInstruments('shutter', 'ferme');
        %Camera_PrincetonInstruments('shutter', 'ouvert');
        %
        %Note importante: le 31 janvier 2014 nous avons ajoute un
        %inverseur a l'entree de la boite de controle. C'est pourquoi il
        %faut inverser le ouvert et le ferme.
        if isstruct(PARAM)
            if isfield(PARAM, 'shutter')
                PARAM.shutter = PARAM.shutter;
            else
                PARAM.shutter = 'ouvert';
            end
        else
            clear PARAM
            PARAM.shutter = varargin{1};
        end

        switch upper(PARAM.shutter)
            case 'OUVERT'
                % Note: mode OPEN_NEVER = 0 Volt en sortie de la CCD 
                %                       = electro-aimant pas alimente 
                %                       = shutter OUVERT (je sais c'est bizarre)  % Avant le 31 janvier 2014
                %                       = shutter FERME % Apres le 31 janvier 2014
                %Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 'OPEN_NEVER') % Avant le 31 janvier 2014
                Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 'OPEN_PRE_SEQUENCE') % Apres le 31 janvier 2014
            case 'FERME'
                %Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 'OPEN_PRE_SEQUENCE') % Avant le 31 janvier 2014
                Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 'OPEN_NEVER') % Apres le 31 janvier 2014
        end
        %%%%%
        % Pour une raison inconnue, on ne peut pas changer l'etat du shutter sans
        % faire d'acquisition. La suite du programme fait une acquisition minimale.
        Camera_PrincetonInstruments('spectre', struct('t_acc', .001, 'n_acc', 1));

    case {'GET_PARAMETER_ALL'}
        [varargout{1} varargout{2}] = Camera_PrincetonInstruments('GET_PARAMETER', varargin{:});
        disp(varargout{2})

    case {'GET_PARAMETER' 'PL_GET_PARAM'}
        %Lit un parametre de la Camera
        %
        %Il y a 2 façons de lire un parametre
        %
        %On spécifie le nom du parametre
        %   Camera_PrincetonInstruments('get_parameter', 'PARAM_SHTR_OPEN_MODE')
        %
        %On passe le nom du parametre dans une structure
        %   Camera_PrincetonInstruments('get_parameter', struct('parameter_name', 'PARAM_SHTR_OPEN_MODE'))

        %lit les parametres d'entrée
        if isstruct(varargin{1})
            PARAM = varargin{1};
            parameter = PARAM.parameter_name;
        else
            parameter = varargin{1};
        end

        msg = [];
        if ~libisloaded(Librairie_Camera) 
            disp(['La bibliotheque ' Librairie_Camera '.dll n''a pas ete chargee en memoire' ]);
            loadlibrary (Librairie_Camera, 'pixis.h');
        end
        x = 53; % Tout et n'importe quoi, et SURTOUT n'importe quoi !
        xp = libpointer('uint32Ptr', x);% Ce pointeur de 32 bits devrait convenir pour la plupart des void* numeriques             
                
        [dump avail]    = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_AVAIL, xp);
        
        %disp(avail)  
        %disp(dump)
        errtest(dump)
        %parameter
        
        msg = [msg ['  AVAIL=' int2str(avail)]];
        
        if  avail
            [dump access] = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_ACCESS, xp);
            errtest(dump);
            %disp(access)
            %disp(Camera_PI.PVCAM)
            
            switch (access)
                case Camera_PI.PVCAM.ACC_ERROR
                    str = 'ERROR';
                    readable = false; writeable = false;
                case Camera_PI.PVCAM.ACC_READ_ONLY
                    str = 'READ_ONLY';
                    readable = true; writeable = false;
                case Camera_PI.PVCAM.ACC_READ_WRITE
                    str = 'READ_WRITE';
                    readable = true; writeable = true;
                case Camera_PI.PVCAM.ACC_EXIST_CHECK_ONLY
                    str = 'EXIST_CHECK_ONLY';
                    readable = false; writeable = false;
                case Camera_PI.PVCAM.ACC_WRITE_ONLY
                    str = 'WRITE_ONLY';
                    readable = false; writeable = true;
                otherwise
                    str = 'UNKNOWN_ACCESS';
                    readable = false; writeable = false;
            end % access
            msg = [msg ['  ACCESS=' int2str(access) '-' str]];
            
%             readable
%             writeable

            if (readable || writeable)
                [dump type] = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_TYPE, xp); errtest(dump);
                switch (type);
                    case Camera_PI.PVCAM.TYPE_CHAR_PTR
                        str = 'CHAR_PTR (String)';
                        numeric = false; string = true; enum = false;
                        x = blanks(500);
                        xp = libpointer('voidPtr', [uint8(x) 0]);
                    case Camera_PI.PVCAM.TYPE_INT8
                        str = 'INT8';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('int8Ptr', int8(x));
                    case Camera_PI.PVCAM.TYPE_UNS8
                        str = 'UNS8';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('uint8Ptr', uint8(x));
                    case Camera_PI.PVCAM.TYPE_INT16
                        str = 'INT16';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('int16Ptr', int16(x));
                    case Camera_PI.PVCAM.TYPE_UNS16
                        str = 'UNS16';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('uint16Ptr', uint16(x));
                    case Camera_PI.PVCAM.TYPE_INT32
                        str = 'INT32';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('int32Ptr', int32(x));
                    case Camera_PI.PVCAM.TYPE_UNS32
                        str = 'UNS32';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('uint32Ptr', uint32(x));
                    case Camera_PI.PVCAM.TYPE_FLT64
                        str = 'FLT64';
                        numeric = true; string = false; enum = false;
                        xp = libpointer('doublePtr', x);
                    case Camera_PI.PVCAM.TYPE_ENUM
                        str = 'ENUM';
                        numeric = false; string = false; enum = true;
                    case Camera_PI.PVCAM.TYPE_BOOLEAN
                        str = 'BOOLEAN';
                        numeric = true; string = false; enum = false;
                    case Camera_PI.PVCAM.TYPE_VOID_PTR
                        str = 'VOID_PTR';
                        numeric = false; string = false; enum = false;
                    case Camera_PI.PVCAM.TYPE_VOID_PTR_PTR
                        str = 'VOID_PTR_PTR';
                        numeric = false; string = false; enum = false;
                    otherwise
                        str = 'UNKNOWN_TYPE';
                        numeric = false; string = false; enum = false;
                end
                msg = [msg ['  TYPE=' int2str(type) '-' str]];
            end % readable or writeable
            
%             numeric
%             string
%             enum

            if readable
                [dump value]     = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_CURRENT, xp);
                [dump default]   = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_DEFAULT, xp);              
                if numeric
                    msg = [msg ['  DEFAULT=' int2str(default)]];
                    msg = [msg ['  VALUE=' int2str(value)]];
                    [dump minimum]   = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_MIN, xp);
                    [dump maximum]   = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_MAX, xp);
                    [dump incr]  = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_INCREMENT, xp);
                    msg = [msg ['  MIN=' int2str(minimum)]];
                    msg = [msg ['  MAX=' int2str(maximum)]];
                    msg = [msg ['  INCR=' int2str(incr)]];
                end
                if string                  
                    value = deblank(char(value));
                    default = deblank(char(default));
                    msg = [msg ['  VALUE=' value '  DEFAULT=' default]];                    
                end
                if enum
                    [dump count]  = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_COUNT, xp);
                    %indexValues=0:(count-1);
                    enumDesc={};
                    for i=1:count
                        [dump len] = calllib(Librairie_Camera, 'pl_enum_str_length', Camera_PI.handle, Camera_PI.PVCAM.(parameter), i-1, 0);
                        x = blanks(len);
                        [dump enumValue desc] = calllib(Librairie_Camera, 'pl_get_enum_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), i-1, 0, x, len); errtest(dump);
                        if enumValue==value, indexValue=i; end
                        enumDesc=[enumDesc desc];
                    end
                    desc=enumDesc{indexValue};
                    msg = [msg ['  DEFAULT=' int2str(default)]];
                    msg = [msg ['  VALUE=' int2str(value) ' (' desc ')']];
                end
            end % readable
        else
            value = nan;
        end
        %disp(msg)
        
        varargout{1} = value;
        varargout{2} = msg;

    case {'PL_SET_PARAM' 'SET_PARAMETER'}
        %Modifie un parametre de la Camera
        %
        %Il y a 4 façons de modifier un parametre
        %
        %On spécifie le nom du parametre et sa valeur
        %   Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 0)
        %
        %On spécifie le nom du parametre et le nom de la valeur
        %   Camera_PrincetonInstruments('set_parameter', 'PARAM_SHTR_OPEN_MODE', 'OPEN_NEVER')
        %
        %On passe le nom du parametre et de la valeur dans une structure
        %    Camera_PrincetonInstruments('set_parameter', struct('parameter_name', 'PARAM_SHTR_OPEN_MODE', 'parameter_value', 0))
        %
        %On passe le nom du parametre et le nom de la valeur dans une structure
        %   Camera_PrincetonInstruments('set_parameter', struct('parameter_name', 'PARAM_SHTR_OPEN_MODE', 'parameter_value_name', 'OPEN_PRE_SEQUENCE'))

        %lit les parametres d'entrée
        
        if isstruct(varargin{1})
            PARAM = varargin{1};
            parameter = PARAM.parameter_name;
            if isfield(PARAM, 'parameter_value')
                value = PARAM.parameter_value;
            else
                parameter_value_name = PARAM.parameter_value_name;
                value = Camera_PI.PVCAM.(parameter_value_name);
            end
        else
            parameter = varargin{1};
            if ischar(varargin{2})             
                parameter_value_name = varargin{2};
                Camera_PI.a=1;
                value = Camera_PI.PVCAM.(parameter_value_name);
            else
                value = varargin{2};
            end
        end
       
        x = 56; % Tout et n'importe quoi, et SURTOUT n'importe quoi !
        xp = libpointer('uint32Ptr', x);
             
        [dump type]     = calllib2(Librairie_Camera, 'pl_get_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), Camera_PI.PVCAM.ATTR_TYPE, xp);
        
        errtest(dump);
        switch (type);
            case Camera_PI.PVCAM.TYPE_CHAR_PTR
                str = 'CHAR_PTR (String)';
                numeric = false; string = true; enum = false;
                x = blanks(500);
                xp = libpointer('voidPtr', [uint8(x) 0]);
            case Camera_PI.PVCAM.TYPE_INT8
                str = 'INT8';
                numeric = true; string = false; enum = false;
                xp = libpointer('int8Ptr', int8(x));
            case Camera_PI.PVCAM.TYPE_UNS8
                str = 'UNS8';
                numeric = true; string = false; enum = false;
                xp = libpointer('uint8Ptr', uint8(x));
            case Camera_PI.PVCAM.TYPE_INT16
                str = 'INT16';
                numeric = true; string = false; enum = false;
                xp = libpointer('int16Ptr', int16(x));
            case Camera_PI.PVCAM.TYPE_UNS16
                str = 'UNS16';
                numeric = true; string = false; enum = false;
                xp = libpointer('uint16Ptr', uint16(x));
            case Camera_PI.PVCAM.TYPE_INT32
                str = 'INT32';
                numeric = true; string = false; enum = false;
                xp = libpointer('int32Ptr', int32(x));
            case Camera_PI.PVCAM.TYPE_UNS32
                str = 'UNS32';
                numeric = true; string = false; enum = false;
                xp = libpointer('uint32Ptr', uint32(x));
            case Camera_PI.PVCAM.TYPE_FLT64
                str = 'FLT64';
                numeric = true; string = false; enum = false;
                xp = libpointer('doublePtr', x);
            case Camera_PI.PVCAM.TYPE_ENUM
                str = 'ENUM';
                numeric = false; string = false; enum = true;
            case Camera_PI.PVCAM.TYPE_BOOLEAN
                str = 'BOOLEAN';
                numeric = true; string = false; enum = false;
            case Camera_PI.PVCAM.TYPE_VOID_PTR
                str = 'VOID_PTR';
                numeric = false; string = false; enum = false;
            case Camera_PI.PVCAM.TYPE_VOID_PTR_PTR
                str = 'VOID_PTR_PTR';
                numeric = false; string = false; enum = false;
            otherwise
                str = 'UNKNOWN_TYPE';
                numeric = false; string = false; enum = false;
        end

        if numeric
            xp.Value = value;
            dump = calllib2(Librairie_Camera, 'pl_set_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), xp); errtest(dump);
        end
        if string
        end
        if enum
            index = value;
            [dump len] = calllib(Librairie_Camera, 'pl_enum_str_length', Camera_PI.handle, Camera_PI.PVCAM.(parameter), index, 0);
            x = blanks(len);
            [dump value desc] = calllib(Librairie_Camera, 'pl_get_enum_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), index, 0, x, len); errtest(dump);
            dump = calllib(Librairie_Camera, 'pl_set_param', Camera_PI.handle, Camera_PI.PVCAM.(parameter), value);
        end

    case 'ENREGISTRE_CONFIGURATION'
        if nargin==1
            [fichier, nom_repertoire, FilterIndex] = uiputfile('.m', 'Fichier de sauvegarde de la configuration de la camera');
            fichier = [nom_repertoire fichier];
        else
            fichier = varargin{1};
        end
        if ~strcmp(fichier(end-1:end), '.m')
            fichier = [fichier '.m'];
        end
        fid = fopen(fichier, 'w');

        fprintf(fid, ('%% Fichier de configuration de la camera \n'));
        fprintf(fid, (['%% 	genere par Camera_PrincetonInstruments(''enregistre_configuration'')\n ']));
        fprintf(fid, (['%% 	enregistre le ' datestr(now) '\n']));
        fprintf(fid, ('%%  \n'));

        fprintf(fid, 'Camera_PrincetonInstruments(''initialise'');\n');
        fprintf(fid, (['Camera_PrincetonInstruments(''gain'', ' num2str(Camera_PrincetonInstruments('gain')) ');\n']));
        fprintf(fid, (['Camera_PrincetonInstruments(''temp_setpoint'', ' num2str(Camera_PrincetonInstruments('temp_setpoint')) ');\n']));
        frequence = round(1/(double(Camera_PrincetonInstruments('get_parameter', 'PARAM_PIX_TIME'))*1e-9));
        switch frequence
            case 2e6
                frequence = '2 MHz';
            case 100e3
                frequence = '100 kHz';
        end
        fprintf(fid, (['Camera_PrincetonInstruments(''speed'', ''' frequence ''');\n']));

        fprintf(fid, ('%%  \n'));

        out = fclose(fid);
        switch out
            case 0
                disp('Configuration du TriVista enregistree ')
                disp(['  avec succes dans le fichier: ' fichier])
            case -1
                disp(['Erreur dans l''enregistrement de la configuration du TriVista' ])
        end
        
    case 'LIVE_IMAGE'
        if ~isfield(PARAM, 't_acc')
            PARAM.t_acc = 1;
        end
        while 1
            y = Camera_PrincetonInstruments('IMAGE', PARAM);
            minimum = min(min(y(10:end, :)));
            maximum = max(max(y(10:end, :)));
             somme = sum(sum(y(10:end, 400:800)))-570*size(y(10:end, 400:800), 1)*size(y(10:end, 400:800), 2);
            image((y-minimum)/(maximum-minimum)*256)
            title({['Max: ' num2str(maximum)] ['Min: ' num2str(minimum)] ['Somme: ' num2str(somme)]})
            pause(.01)
        end
        
    case 'LIVE_SPECTRE'
        if ~isfield(PARAM, 't_acc')
            PARAM.t_acc = 1;
        end
        while 1
            y = Camera_PrincetonInstruments('SPECTRE', PARAM);
            minimum = min(y);
            maximum = max(y);
            plot((y-minimum)/(maximum-minimum))
            title({['Max: ' num2str(maximum)] ['Min: ' num2str(minimum)]})
            pause(.01)
        end
        
    otherwise
        disp([mfilename '.m :' fonction ': fonction pas encore implementee'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function errtest(dump)
%ERRTEST : Donne des informations sur la derniere erreur retournee par PVCAM
%   La bibliotheque pvcam32.dll maintient des codes d'erreurs. Lorsqu'une
%   fonction plante, d'une part elle retourne la valeur 0 (dans dump) et
%   d'autre part elle change la valeur du code d'erreur. A chaque fois
%   qu'une fonction marche correctement, le code d'erreur est remis a 0.
%   La fonction errtest permet de verifier si une erreur s'est produite, et
%   si une erreur s'est produite, de savoir de quelle erreur il s'agit.
if dump==0
    if (libisloaded('pvcam32'))
        errorCode = calllib('pvcam32', 'pl_error_code');
        msg=blanks(255);
        [dump2 msg] = calllib('pvcam32', 'pl_error_message', errorCode, msg);
        disp(['Une erreur a ete detectee. Code : ' int2str(errorCode) '. Message : ' msg '.']);
        error('Voir dans l''annexe A du manuel de PVCAM');
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = PVCAMConstants

%/*********************** Constant & Type Definitions *************************/

%/************************ Class 2: Data types ********************************/
%/* Data type used by pl_get_param with attribute type (ATTR_TYPE).           */
TYPE_CHAR_PTR =     uint32(13);
TYPE_INT8 =         uint32(12);
TYPE_UNS8 =         uint32( 5);
TYPE_INT16 =        uint32( 1);
TYPE_UNS16 =        uint32( 6);
TYPE_INT32 =        uint32( 2);
TYPE_UNS32 =        uint32( 7);
TYPE_UNS64 =        uint32( 8);
TYPE_FLT64 =        uint32( 4);
TYPE_ENUM =         uint32( 9);
TYPE_BOOLEAN =      uint32(11);
TYPE_VOID_PTR =     uint32(14);
TYPE_VOID_PTR_PTR = uint32(15);

%/* defines for classes                                                  */
CLASS0 =      uint32(0);          %/* Camera Communications                      */
CLASS1 =      uint32(1);          %/* Error Reporting                            */
CLASS2 =      uint32(2);          %/* Configuration/Setup                        */
CLASS3 =      uint32(3);          %/* Data Acuisition                            */
CLASS4 =      uint32(4);          %/* Buffer Manipulation                        */
CLASS5 =      uint32(5);          %/* Analysis                                   */
CLASS6 =      uint32(6);          %/* Data Export                                */
CLASS29 =     uint32(29);         %/* Buffer Functions                           */
CLASS30 =     uint32(30);         %/* Utility functions                          */
CLASS31 =     uint32(31);         %/* Memory Functions                           */
CLASS32 =     uint32(32);         %/* CCL Engine                                 */
CLASS91 =     uint32(91);         %/* RS170                                      */
CLASS92 =     uint32(92);         %/* Defect Mapping                             */
CLASS93 =     uint32(93);         %/* Fast frame operations (PIV/ACCUM/Kinetics) */
CLASS94 =     uint32(94);         %/* PTG                                        */
CLASS95 =     uint32(95);         %/* Virtual Chip                               */
CLASS96 =     uint32(96);         %/* Acton diagnostics.                         */
CLASS97 =     uint32(97);         %/* Custom Chip                                */
CLASS98 =     uint32(98);         %/* Custom timing                              */
CLASS99 =     uint32(99);         %/* Trenton diagnostics.                       */

%/************************ Parameter IDs **************************************/
%/* Format: TTCCxxxx, where TT = Data type, CC = Class, xxxx = ID number      */


%/* DEVICE DRIVER PARAMETERS (CLASS 0) */

%/*  Class 0 (next available index for class zero = 6) */

PARAM_DD_INFO_LENGTH        = uint32((CLASS0 *2^16) + (TYPE_INT16 *2^24) + 1);
PARAM_DD_VERSION            = uint32((CLASS0 *2^16) + (TYPE_UNS16 *2^24) + 2);
PARAM_DD_RETRIES            = uint32((CLASS0 *2^16) + (TYPE_UNS16 *2^24) + 3);
PARAM_DD_TIMEOUT            = uint32((CLASS0 *2^16) + (TYPE_UNS16 *2^24) + 4);
PARAM_DD_INFO               = uint32((CLASS0 *2^16) + (TYPE_CHAR_PTR *2^24) + 5);

%/* Camera Parameters Class 2 variables */

%/* Class 2 (next available index for class two = 544) */

%/* CCD skip parameters                                                       */
%/* Min Block. amount to group on the shift register, to through way.         */
PARAM_MIN_BLOCK             = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     +  60);
%/* number of min block groups to use before valid data.                      */
PARAM_NUM_MIN_BLOCK         = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     +  61);
%/* number of strips to clear at one time, before going to the                */
%/* minblk/numminblk scheme                                                   */
PARAM_SKIP_AT_ONCE_BLK      = uint32((CLASS2 *2^16) + (TYPE_INT32 *2^24)     + 536);
%/* Strips per clear. Used to define how many clears to use for continous     */
%/* clears and with clears to define the clear area at the beginning of an    */
%/* experiment.                                                               */
PARAM_NUM_OF_STRIPS_PER_CLR = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     +  98);
%/* Set Continuous Clears for Trenton Cameras. This is for clearing while     */
%/* in external trigger.                                                      */
PARAM_CONT_CLEARS           = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)     + 540);
%/* Only applies to Thompson ST133 5Mhz                                       */
%/* enables or disables anti-blooming.                                        */
PARAM_ANTI_BLOOMING         = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 293);
%/* This applies to ST133 1Mhz and 5Mhz and PentaMax V5 controllers. For the  */
%/* ST133 family this controls whether the BNC (not scan) is either not scan  */
%/* or shutter for the PentaMax V5, this can be not scan, shutter, not ready, */
%/* clearing, logic 0, logic 1, clearing, and not frame transfer image shift. */
%/* See enum below for possible values                                        */
PARAM_LOGIC_OUTPUT          = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      +  66);
%/* Edge Trigger defines whether the external sync trigger is positive or     */
%/* negitive edge active. This is for the ST133 family (1 and 5 Mhz) and      */
%/* PentaMax V5.0.                                                            */
%/* see enum below for possible values.                                       */
PARAM_EDGE_TRIGGER          = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 106);
%/* Intensifier gain is currently only used by the PI-Max and has a range of  */
%/* 0-255                                                                     */
PARAM_INTENSIFIER_GAIN      = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 216);
%/* Shutter, Gate, or Safe mode, for the PI-Max.                              */
PARAM_SHTR_GATE_MODE        = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 217);
%/* ADC offset setting.                                                       */
PARAM_ADC_OFFSET            = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 195);
%/* CCD chip name.    */
PARAM_CHIP_NAME             = uint32((CLASS2 *2^16) + (TYPE_CHAR_PTR *2^24)  + 129);

PARAM_COOLING_MODE          = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 214);
PARAM_PREAMP_DELAY          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 502);
PARAM_PREFLASH              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 503);
PARAM_COLOR_MODE            = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 504);
PARAM_MPP_CAPABLE           = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 224);
PARAM_PREAMP_OFF_CONTROL    = uint32((CLASS2 *2^16) + (TYPE_UNS32 *2^24)     + 507);
PARAM_SERIAL_NUM            = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 508);

%/* CCD Dimensions and physical characteristics                               */
%/* pre and post dummies of CCD.                                              */
PARAM_PREMASK               = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  53);
PARAM_PRESCAN               = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  55);
PARAM_POSTMASK              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  54);
PARAM_POSTSCAN              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  56);
PARAM_PIX_PAR_DIST          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 500);
PARAM_PIX_PAR_SIZE          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  63);
PARAM_PIX_SER_DIST          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 501);
PARAM_PIX_SER_SIZE          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  62);
PARAM_SUMMING_WELL          = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   + 505);
PARAM_FWELL_CAPACITY        = uint32((CLASS2 *2^16) + (TYPE_UNS32 *2^24)     + 506);
%/* Y dimension of active area of CCD chip */
PARAM_PAR_SIZE              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  57);
%/* X dimension of active area of CCD chip */
PARAM_SER_SIZE              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  58);
%/* X dimension of active area of CCD chip */
PARAM_ACCUM_CAPABLE         = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   + 538);


PARAM_FTSCAN                = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     +  59);

%/* customize chip dimension */
PARAM_CUSTOM_CHIP           = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   +  87);

%/* customize chip timing */
PARAM_CUSTOM_TIMING         = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   +  88);
PARAM_PAR_SHIFT_TIME        = uint32((CLASS2 *2^16) + (TYPE_UNS32 *2^24)     + 545);
PARAM_SER_SHIFT_TIME        = uint32((CLASS2 *2^16) + (TYPE_UNS32 *2^24)     + 546);

%/* Kinetics Window Size */
PARAM_KIN_WIN_SIZE          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 126);


%/* General parameters */
%/* Is the controller on and running? */
PARAM_CONTROLLER_ALIVE      = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   + 168);
%/* Readout time of current ROI, in ms */
PARAM_READOUT_TIME          = uint32((CLASS2 *2^16) + (TYPE_FLT64 *2^24)     + 179);


%/* CAMERA PARAMETERS (CLASS 2) */
PARAM_CLEAR_CYCLES          = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 97);
PARAM_CLEAR_MODE            = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 523);
PARAM_FRAME_CAPABLE         = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   + 509);
PARAM_PMODE                 = uint32((CLASS2 *2^16) + (TYPE_ENUM  *2^24)     + 524);
PARAM_CCS_STATUS            = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 510);

%/* This is the actual temperature of the detector. This is only a get, not a */
%/* set                                                                       */
PARAM_TEMP                  = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 525);
%/* This is the desired temperature to set. */
PARAM_TEMP_SETPOINT         = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 526);
PARAM_CAM_FW_VERSION        = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 532);
PARAM_HEAD_SER_NUM_ALPHA    = uint32((CLASS2 *2^16) + (TYPE_CHAR_PTR *2^24)  + 533);
PARAM_PCI_FW_VERSION        = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 534);
PARAM_CAM_FW_FULL_VERSION	= uint32((CLASS2 *2^16) + (TYPE_CHAR_PTR *2^24)  + 534);

%/* Exsposure mode, timed strobed etc, etc */
PARAM_EXPOSURE_MODE         = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 535);

%/* SPEED TABLE PARAMETERS (CLASS 2) */

PARAM_BIT_DEPTH             = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 511);
PARAM_GAIN_INDEX            = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 512);
PARAM_SPDTAB_INDEX          = uint32((CLASS2 *2^16) + (TYPE_INT16 *2^24)     + 513);
%/* define which port (amplifier on shift register) to use. */
PARAM_READOUT_PORT          = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 247);
PARAM_PIX_TIME              = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 516);

%/* SHUTTER PARAMETERS (CLASS 2) */

PARAM_SHTR_CLOSE_DELAY      = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 519);
PARAM_SHTR_OPEN_DELAY       = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 520);
PARAM_SHTR_OPEN_MODE        = uint32((CLASS2 *2^16) + (TYPE_ENUM  *2^24)     + 521);
PARAM_SHTR_STATUS           = uint32((CLASS2 *2^16) + (TYPE_ENUM  *2^24)     + 522);
PARAM_SHTR_CLOSE_DELAY_UNIT = uint32((CLASS2 *2^16) + (TYPE_ENUM  *2^24)     + 543);  %/* use enum TIME_UNITS to specify the unit */


%/* I/O PARAMETERS (CLASS 2) */

PARAM_IO_ADDR               = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 527);
PARAM_IO_TYPE               = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 528);
PARAM_IO_DIRECTION          = uint32((CLASS2 *2^16) + (TYPE_ENUM *2^24)      + 529);
PARAM_IO_STATE              = uint32((CLASS2 *2^16) + (TYPE_FLT64 *2^24)     + 530);
PARAM_IO_BITDEPTH           = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 531);

%/* GAIN MULTIPLIER PARAMETERS (CLASS 2) */

PARAM_GAIN_MULT_FACTOR      = uint32((CLASS2 *2^16) + (TYPE_UNS16 *2^24)     + 537);
PARAM_GAIN_MULT_ENABLE      = uint32((CLASS2 *2^16) + (TYPE_BOOLEAN *2^24)   + 541);

%/* ACQUISITION PARAMETERS (CLASS 3) */
%/* (next available index for class three = 11) */

PARAM_EXP_TIME              = uint32((CLASS3 *2^16) + (TYPE_UNS16 *2^24)     +   1);
PARAM_EXP_RES               = uint32((CLASS3 *2^16) + (TYPE_ENUM *2^24)      +   2);
PARAM_EXP_MIN_TIME          = uint32((CLASS3 *2^16) + (TYPE_FLT64 *2^24)     +   3);
PARAM_EXP_RES_INDEX         = uint32((CLASS3 *2^16) + (TYPE_UNS16 *2^24)     +   4);

%/* PARAMETERS FOR  BEGIN and END of FRAME Interrupts */
PARAM_BOF_EOF_ENABLE        = uint32((CLASS3 *2^16) + (TYPE_ENUM *2^24)      +   5);
PARAM_BOF_EOF_COUNT         = uint32((CLASS3 *2^16) + (TYPE_UNS32 *2^24)     +   6);
PARAM_BOF_EOF_CLR           = uint32((CLASS3 *2^16) + (TYPE_BOOLEAN *2^24)   +   7);


%/* Test to see if hardware/software can perform circular buffer */
PARAM_CIRC_BUFFER           = uint32((CLASS3 *2^16) + (TYPE_BOOLEAN *2^24)   + 299);

%/* Hardware Will Automatically Stop After A Specified Number of Frames */
PARAM_HW_AUTOSTOP           = uint32((CLASS3 *2^16) + (TYPE_INT16 *2^24)     + 166);

%/************************* Enum Types Parameters *****************************/
%/********************** Class 0: Open Camera Modes ***************************/
%/*
%  Function: pl_cam_open()
%  PI Conversion: CreateController()
%*/
OPEN_EXCLUSIVE              = uint32(0);

%/************************ Class 1: Error message size ************************/
ERROR_MSG_LEN               = uint32(255); %/*No error message will be longer than this*/

%/*********************** Class 2: Cooling type flags *************************/
%/* used with the PARAM_COOLING_MODE parameter id.
%  PI Conversion: NORMAL_COOL = TE_COOLED
%                 CRYO_COOL   = LN_COOLED
%*/
NORMAL_COOL                 = uint32(0);
CRYO_COOL                   = uint32(1);

%/************************** Class 2: Name/ID sizes ***************************/
CCD_NAME_LEN                = uint32(17);  %/* Includes space for the null terminator */
MAX_ALPHA_SER_NUM_LEN       = uint32(32);  %/* Includes space for the null terminator */

%/*********************** Class 2: MPP capability flags ***********************/
%/* used with the PARAM_MPP_CAPABLE parameter id.                             */
MPP_UNKNOWN                 = uint32(0);
MPP_ALWAYS_OFF              = uint32(1);
MPP_ALWAYS_ON               = uint32(2);
MPP_SELECTABLE              = uint32(3);

%/************************** Class 2: Shutter flags ***************************/
%/* used with the PARAM_SHTR_STATUS parameter id.
%  PI Conversion: n/a   (returns SHTR_OPEN)
%*/
SHTR_FAULT                  = uint32(0);
SHTR_OPENING                = uint32(1);
SHTR_OPEN                   = uint32(2);
SHTR_CLOSING                = uint32(3);
SHTR_CLOSED                 = uint32(4);
SHTR_UNKNOWN                = uint32(5);

%/************************ Class 2: Pmode constants ***************************/
%/* used with the PARAM_PMODE parameter id.                                   */
PMODE_NORMAL                = uint32(0);
PMODE_FT                    = uint32(1);
PMODE_MPP                   = uint32(2);
PMODE_FT_MPP                = uint32(3);
PMODE_ALT_NORMAL            = uint32(4);
PMODE_ALT_FT                = uint32(5);
PMODE_ALT_MPP               = uint32(6);
PMODE_ALT_FT_MPP            = uint32(7);
PMODE_INTERLINE             = uint32(8);
PMODE_KINETICS              = uint32(9);
PMODE_DIF                   = uint32(10);

%/************************ Class 2: Color support constants *******************/
%/* used with the PARAM_COLOR_MODE parameter id.                              */
COLOR_NONE                  = uint32(0);
COLOR_RGGB                  = uint32(2);

%/************************ Class 2: Attribute IDs *****************************/
%/*
%  Function: pl_get_param()
%*/
ATTR_CURRENT                = uint32(0);
ATTR_COUNT                  = uint32(1);
ATTR_TYPE                   = uint32(2);
ATTR_MIN                    = uint32(3);
ATTR_MAX                    = uint32(4);
ATTR_DEFAULT                = uint32(5);
ATTR_INCREMENT              = uint32(6);
ATTR_ACCESS                 = uint32(7);
ATTR_AVAIL                  = uint32(8);

%/************************ Class 2: Access types ******************************/
%/*
%  Function: pl_get_param( ATTR_ACCESS )
%*/
ACC_ERROR                   = uint32(0);
ACC_READ_ONLY               = uint32(1);
ACC_READ_WRITE              = uint32(2);
ACC_EXIST_CHECK_ONLY        = uint32(3);
ACC_WRITE_ONLY              = uint32(4);
%/* This enum is used by the access Attribute */

%/************************ Class 2: I/O types *********************************/
%/* used with the PARAM_IO_TYPE parameter id.                                 */
IO_TYPE_TTL                 = uint32(0);
IO_TYPE_DAC                 = uint32(1);

%/************************ Class 2: I/O direction flags ***********************/
%/* used with the PARAM_IO_DIRECTION parameter id.                            */
IO_DIR_INPUT                = uint32(0);
IO_DIR_OUTPUT               = uint32(1);
IO_DIR_INPUT_OUTPUT         = uint32(2);

%/************************ Class 2: I/O port attributes ***********************/
IO_ATTR_DIR_FIXED           = uint32(0);
IO_ATTR_DIR_VARIABLE_ALWAYS_READ = uint32(1);

%/************************ Class 2: Trigger polarity **************************/
%/* used with the PARAM_EDGE_TRIGGER parameter id.                            */
EDGE_TRIG_POS               = uint32(2);
EDGE_TRIG_NEG               = uint32(3);

%/************************ Class 2: Logic Output ******************************/
%/* used with the PARAM_LOGIC_OUTPUT parameter id.                            */
OUTPUT_NOT_SCAN             = uint32(0);
OUTPUT_SHUTTER              = uint32(1);
OUTPUT_NOT_RDY              = uint32(2);
OUTPUT_LOGIC0               = uint32(3);
OUTPUT_CLEARING             = uint32(4);
OUTPUT_NOT_FT_IMAGE_SHIFT   = uint32(5);
OUTPUT_RESERVED             = uint32(6);
OUTPUT_LOGIC1               = uint32(7);

%/************************ Class 2: PI-Max intensifer gating settings *********/
%/* used with the PARAM_SHTR_GATE_MODE parameter id.                          */
INTENSIFIER_SAFE            = uint32(0);
INTENSIFIER_GATING          = uint32(1);
INTENSIFIER_SHUTTER         = uint32(2);

%/************************ Class 2: Readout Port ******************************/
%/* used with the PARAM_READOUT_PORT parameter id.                            */
READOUT_PORT_MULT_GAIN      = uint32(0);
READOUT_PORT_NORMAL         = uint32(1);
READOUT_PORT_LOW_NOISE      = uint32(2);
READOUT_PORT_HIGH_CAP       = uint32(3);
%/* deprecated */
READOUT_PORT1               = uint32(0);
READOUT_PORT2               = uint32(1);

%/************************ Class 2: Anti Blooming *****************************/
%/* used with the PARAM_ANTI_BLOOMING parameter id.                           */
ANTIBLOOM_NOTUSED           = uint32(0);
ANTIBLOOM_INACTIVE          = uint32(1);
ANTIBLOOM_ACTIVE            = uint32(2);

%/************************ Class 2: Clearing mode flags ***********************/
%/* used with the PARAM_CLEAR_MODE parameter id.                              */
CLEAR_NEVER                 = uint32(0);
CLEAR_PRE_EXPOSURE          = uint32(1);
CLEAR_PRE_SEQUENCE          = uint32(2);
CLEAR_POST_SEQUENCE         = uint32(3);
CLEAR_PRE_POST_SEQUENCE     = uint32(4);
CLEAR_PRE_EXPOSURE_POST_SEQ = uint32(5);

%/************************ Class 2: Shutter mode flags ************************/
%/*
%  Function: pl_set_param ( PARAM_SHTR_OPEN_MODE )

%  PI Conversion: OPEN_NEVER:        SHUTTER_CLOSE
%                 OPEN_PRE_EXPOSURE: SHUTTER_OPEN  & CMP_SHT_PREOPEN = FALSE
%                 OPEN_PRE_SEQUENCE: SHUTTER_DISABLED_OPEN
%                 OPEN_PRE_TRIGGER:  SHUTTER_OPEN & CMP_SHT_PREOPEN = TRUE
%                 OPEN_NO_CHANGE:    SHUTTER_OPEN
%*/
OPEN_NEVER                  = uint32(0);
OPEN_PRE_EXPOSURE           = uint32(1);
OPEN_PRE_SEQUENCE           = uint32(2);
OPEN_PRE_TRIGGER            = uint32(3);
OPEN_NO_CHANGE              = uint32(4);

%/************************ Class 2: Exposure mode flags ***********************/
%/* used with the PARAM_EXPOSURE_MODE parameter id.
%  Functions: pl_exp_setup_cont()
%             pl_exp_setup_seq()
%
%  PI Conversion:
%
%         Readout Mode: Normal           ROM_KINETICS                       ROM_DIF
%
%                       PMODE_NORMAL     PMODE_KINETICS            PMODE_DIF
%                       PMODE_FT
%                       PMODE_INTERLINE
%                                                                  PI-Max II     PI-Max(org)
%  -----------------------------------------------------------------------------------------
%            BULB_MODE:                                            CTRL_DIF_STM  CTRL_EEC
%         STROBED_MODE: CTRL_EXTSYNC     CTRL_KINETICS_MULTIPLE    CTRL_DIF_DTM  CTRL_ESABI
%           TIMED_MODE: CTRL_FREERUN     CTRL_KINETICS_NO_TRIGGER
%   TRIGGER_FIRST_MODE:                  CTRL_KINETICS_SINGLE                    CTRL_IEC
%      INT_STROBE_MODE: CTRL_INTERNAL_SYNC(PTG)
%
%  VARIABLE_TIMED_MODE:
%           FLASH_MODE:
%
%*/
TIMED_MODE                  = uint32(0);
STROBED_MODE                = uint32(1);
BULB_MODE                   = uint32(2);
TRIGGER_FIRST_MODE          = uint32(3);
FLASH_MODE                  = uint32(4);
VARIABLE_TIMED_MODE         = uint32(5);
INT_STROBE_MODE             = uint32(6);

%/********************** Class 3: Readout status flags ************************/
%/*
%  Function: pl_exp_check_status()
%  PI Conversion: PICM_LockCurrentFrame()
%                 PICM_Chk_Data()
%
%    if NEWDATARDY or NEWDATAFIXED     READOUT_COMPLETE
%    else if RUNNING                   ACQUISITION_IN_PROGRESS
%    else if INITIALIZED or DONEDCOK   READOUT_NOT_ACTIVE
%    else                              READOUT_FAILED
%
%*/
READOUT_NOT_ACTIVE          = uint32(0);
EXPOSURE_IN_PROGRESS        = uint32(1);
READOUT_IN_PROGRESS         = uint32(2);
READOUT_COMPLETE            = uint32(3);     %/* Means frame available for a circular buffer acq */
FRAME_AVAILABLE = READOUT_COMPLETE;  %/* New camera status indicating at least one frame is available */
READOUT_FAILED              = uint32(4);
ACQUISITION_IN_PROGRESS     = uint32(5);
MAX_CAMERA_STATUS           = uint32(6);

%/********************** Class 3: Abort Exposure flags ************************/
%/*
%  Function: pl_exp_abort()
%  PI Conversion: controller->Stop(), enum spec ignored
%*/
CCS_NO_CHANGE               = uint32(0);
CCS_HALT                    = uint32(1);
CCS_HALT_CLOSE_SHTR         = uint32(2);
CCS_CLEAR                   = uint32(3);
CCS_CLEAR_CLOSE_SHTR        = uint32(4);
CCS_OPEN_SHTR               = uint32(5);
CCS_CLEAR_OPEN_SHTR         = uint32(6);

%/************************ Class 3: Event constants ***************************/
EVENT_START_READOUT         = uint32(0);
EVENT_END_READOUT           = uint32(1);

%/************************ Class 3: EOF/BOF constants *************************/
%/* used with the PARAM_BOF_EOF_ENABLE parameter id.                          */
NO_FRAME_IRQS               = uint32(0);
BEGIN_FRAME_IRQS            = uint32(1);
END_FRAME_IRQS              = uint32(2);
BEGIN_END_FRAME_IRQS        = uint32(3);

%/************************ Class 3: Continuous Mode constants *****************/
%/*
%  Function: pl_exp_setup_cont()
%*/
CIRC_NONE                   = uint32(0);
CIRC_OVERWRITE              = uint32(1);
CIRC_NO_OVERWRITE           = uint32(2);

%/************************ Class 3: Fast Exposure Resolution constants ********/
%/* used with the PARAM_EXP_RES parameter id.                                 */
EXP_RES_ONE_MILLISEC        = uint32(0);
EXP_RES_ONE_MICROSEC        = uint32(1);
EXP_RES_ONE_SEC             = uint32(2);

%/************************ Class 3: I/O Script Locations **********************/
SCR_PRE_OPEN_SHTR           = uint32(0);
SCR_POST_OPEN_SHTR          = uint32(1);
SCR_PRE_FLASH               = uint32(2);
SCR_POST_FLASH              = uint32(3);
SCR_PRE_INTEGRATE           = uint32(4);
SCR_POST_INTEGRATE          = uint32(5);
SCR_PRE_READOUT             = uint32(6);
SCR_POST_READOUT            = uint32(7);
SCR_PRE_CLOSE_SHTR          = uint32(8);
SCR_POST_CLOSE_SHTR         = uint32(9);

%/************************* Class 3: Region Definition ************************/
% typedef struct
% {
%   uns16 s1;                     %/* First pixel in the serial register */
%   uns16 s2;                     %/* Last pixel in the serial register */
%   uns16 sbin;                   %/* Serial binning for this region */
%   uns16 p1;                     %/* First row in the parallel register */
%   uns16 p2;                     %/* Last row in the parallel register */
%   uns16 pbin;                   %/* Parallel binning for this region */
% }
% rgn_type, PV_PTR_DECL rgn_ptr;
% typedef const rgn_type PV_PTR_DECL rgn_const_ptr;

%/********************** Class 4: Buffer bit depth flags **********************/
PRECISION_INT8              = uint32(0);
PRECISION_UNS8              = uint32(1);
PRECISION_INT16             = uint32(2);
PRECISION_UNS16             = uint32(3);
PRECISION_INT32             = uint32(4);
PRECISION_UNS32             = uint32(5);

%/************************** Class 6: Export Control **************************/
% typedef struct
% {
%   rs_bool rotate;           %/* TRUE=Rotate the data during export            */
%   rs_bool x_flip;           %/* TRUE=Flip the data horizontally during export */
%   rs_bool y_flip;           %/* TRUE=Flip the data vertically during export   */
%   int16 precision;          %/* Bits in output data, see constants            */
%   int16 windowing;          %/* See list of constants                         */
%   int32 max_inten;          %/* Highest intensity, if windowing               */
%   int32 min_inten;          %/* Lowest intensity, if windowing                */
%   int16 output_x_size;      %/* Controls output array size                    */
%   int16 output_y_size;      %/* Controls output array size                    */
% }
% export_ctrl_type, PV_PTR_DECL export_ctrl_ptr;
% typedef const export_ctrl_type PV_PTR_DECL export_ctrl_const_ptr;


%/************************** Classless Entries       **************************/
TU_DAY    = uint32(10);
TU_HOUR   = uint32(5);
TU_MINUTE = uint32(4);
TU_SEC    = uint32(3);
TU_MSEC   = uint32(2);      %/* millisecond  */
TU_USEC   = uint32(1);      %/* microsecond  */
TU_NSEC   = uint32(7);      %/* nanosecond   */
TU_PSEC   = uint32(8);      %/* picosecond   */
TU_FSEC   = uint32(9);      %/* femtosecond  */

s=who;          % la structure handles.PVCAM.etc...
for ii=1:length(s)
    eval(['out.' s{ii} '=' s{ii} ';']); % on sauve dans la structure handles
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [dump out] = calllib2(varargin)

if isnumeric(varargin(end))
    a=uint32(varargin(end));
    [dump out] = calllib(varargin(1:end-1), a)
elseif  isinteger(varargin(end))
    a=uint32(varargin(end));
    [dump out] = calllib(varargin(1:end-1), a)

else
    dump = calllib(varargin{:});
    errtest(dump);

    xp = varargin{end};
    out = get(xp, 'Value');
end









