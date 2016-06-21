function varargout = SP275(fonction,varargin)
%   varargout = SP275(fonction,varargin)
%
%fonction de controle du spectrometre Spectrapro 275
%Exemples:
%   SP275('initialise')
%
% fonction
%   INITIALISE
%               Initialise la communication avec l'appareil
%   CONFIG_INITIALE
%               Configure initiale de l'appareil
%   GRATING
%               Reseau utilise (1-3)
%   OFFSET
%               Decalage de la position
%   GOTO
%               Positionne le reseau    
%   ?NM
%               Lit la position actuelle    
%   ?GRATING
%               Reseau actuel    
    
% 
%26 mars 2015
%   Colin
%   Creation a partir de racal

global spectrapro275
global spectrapro275_OFFSET
global spectrapro275_PRESENT
global debugSP275
global EOSSP275

global sp275GPIB

% la variable suivante permet de choisir la fonction de contrôle gpib
%  'MATLABTOOLBOX'  toolbox gpib de Matlab
%  'LOCAL'          fonction "locale"
%
% La fonction "locale" a besoin des fonctions suivantes:
% - Fonction 'gpib' du 'package' gpib de Tom Davis 
%   que l'on peut trouver a l'adresse 
%   http://www.mathworks.com/matlabcentral/fileexchange/216
% - Fonctions ibfind, ibpad, ibrsc, ibsic et ibsre 
%   du 'package' NI GPIB toolbox de Alaa Makdissi
%   que l'on peut trouver a l'adresse 
%   http://www.mathworks.com/matlabcentral/fileexchange/3140

sp275GPIB = 'local';
EOSSP275 = char(13);

default_adress = 27;

switch upper(fonction)
    %Fonctions 'utilitaires' du compteur de photons
    case {'INITIALISE'}
        global spectrapro275
        spectrapro275 = [];
        spectrapro275 = initialise(default_adress);
        %spectrapro275.EOSCharCode = 'CR';
        %SP275('CONFIG_INITIALE');
        sp275('offset', 0)
    case {'CONFIG_INITIALE'}
        %configuration qui marche
        disp('     Place dans la configutation initiale (patientez)');
        SP275('set-mask', 1); % permet de bloquer l'execution jusqu'a ce que la commande precedente n'est pas terminee avec succes (voir par exemple la derniere ligne de 'GOTO')
        SP275('grating', 2 );
        debugSP275 = 0;
%     case 'CLOSE'
%         fclose(spectrapro275);
    case 'DEBUG'
        debugSP275 = ~debugSP275
    case {'SET-MASK'}
        %
        try
            cible = num2str(varargin{1});
        end
        if debugSP275
            disp([cible ' ' fonction ])
        end
        chaine = [cible ' ' fonction ];
        SP275('ecrire', chaine)
        %fprintf(spectrapro275, [cible ' ' fonction ]);
    case {'GRATING'}
        %Deplace le spectro a un longueur d'onde specifiee
        try
            cible = num2str(varargin{1});
        catch
            cible = varargin{1};
        end
        if debugSP275
            disp([cible ' ' fonction ])
        end
        chaine = [cible ' ' fonction ];
        SP275('ecrire', chaine)
        %attendre
        warning('Changement de reseau. Attendre...')
    case {'OFFSET'}
        %Defini un offset a la longueur d'onde
        %Le offset est defini comme 
        %la longueur d'onde affichee -longueur d'onde reelle
        %Ex. 
        % sp275('offset', 10)
        % sp275('goto', 615)
        % signifie que l'affichage du spectrometre se place a 625
        %
        global spectrapro275_OFFSET
        %Deplace le spectro a un longueur d'onde specifiee
        try
            cible = str2num(varargin{1});
        catch
            cible = varargin{1};
        end
        spectrapro275_OFFSET = cible;
    case {'GOTO'}
        global spectrapro275_OFFSET
        %Deplace le spectro a un longueur d'onde specifiee
        try
            cible = str2num(varargin{1});
        catch
            cible = varargin{1};
        end
        cible = cible + spectrapro275_OFFSET;
        cible = sprintf('%0.1f', cible); %la cible doit avoir UN et un seul chiffre apres le point
        if debugSP275
            disp([cible ' ' fonction ])
        end
        chaine = [cible ' ' fonction ];
        SP275('ecrire',chaine)
        %pause(1)
        %attendre
        attenteGOTO;
    case {'?NM', '?GRATING', '?GRATINGS', '?MASK'}
        %lecture de la longueur d'onde actuelle
        %fprintf(spectrapro275, '?NM');
        varargout{1} = str2num(SP275('demander', fonction));
    case 'LIRE'
        varargout{1} = gpib('rd', spectrapro275);
    case 'ECRIRE'
        chaine = varargin{1};
        switch upper(sp275GPIB)
            case 'LOCAL'
                gpib('wrt', spectrapro275, [chaine EOSSP275]);
            case 'MATLABTOOLBOX'
                %fprintf(spectrapro275, [cible ' ' fonction EOSSP275]);
        end
    case 'DEMANDER'
        chaine = varargin{1};
        SP275('ecrire',chaine)
        pause(0.5);
        varargout{1} = SP275('lire');
    case 'ETAT'
        [spr,ibsta] = gpib('rsp', spectrapro275);
        %status_check(ibsta);
        pret = 0;
        erreur = 0;
        reponse = 0;
        if spr < 0 %codage en base 2 complementaire (bizarre!)
            %donnees a lire
            reponce = 1;
            spr = 128+spr;
        end
        if spr > 1
            erreur = 1;
        end
        if 2*(spr/2-floor(spr/2))
            pret = 1;
        end
        varargout{1} = pret;
        varargout{2} = erreur;
        varargout{3} = reponse;
        
    otherwise
        %disp('fonction pas encore implementee')
end

function attenteGOTO
    %atend d'avoir fini le deplacement
    pret = 0;
    pause(0.1)
    while pret ~= 1
        pause(.01)
        [pret,erreur,reponce] = sp275('etat');
    end

function INSTRUMENT = initialise(addresse)
    global sp275GPIB
    global spectrapro275_OFFSET
    switch upper(sp275GPIB)
        case 'LOCAL' % 
            global ud0
            global INSTRUMENT
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
            INSTRUMENT = gpib('dev', 0, addresse, 0, 13, 1, 0); %voir plus bas pour la signification du 5 element
            disp('     -----------------------------------------')
            disp('     Status Spectrometre SP275');
            [spr,ibsta]=gpib('rsp', INSTRUMENT);
            status_check(ibsta);
            disp('     -----------------------------------------')
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



        case 'MATLABTOOLBOX'

            %initialise(addresse)
            %initialise l'instrument
            global ud0 %carte GPIB
            global INSTRUMENT %instrument
            disp('Initialise Spectrapro 275')
            try
                INSTRUMENT = gpib('ni', 0, addresse);
                INSTRUMENT.EOSMode='read&write';
                fopen(INSTRUMENT);
                spectrapro275_OFFSET = 0
            catch
                disp('   deja initialise')
                INSTRUMENT = instrfind('Type','gpib','Name',['GPIB0-' num2str(addresse)],'Status','open');
            end
            %fprintf(INSTRUMENT, 'ck');
            disp('     -----------------------------------------')
            %0:disabled    %9:100ms
            %1:10micro s   %10:300ms
            %2:30micro s   %11:1s
            %3:100micro s  %12:3s
            %4:300micro s  %13:10s
            %5:1ms         %14:30s
            disp('     Status:');
            disp(['       ' INSTRUMENT.Status]);
            disp('     -----------------------------------------')
            %check_status(ibsta);
            %[spr,ibsta]=gpib('rsp',INSTRUMENT);
            %le 5ieme parametre est le time-out
            %6:3ms         %15:100s
            %7:10ms        %16:300s
            %8:30ms        %17:1000s
    end