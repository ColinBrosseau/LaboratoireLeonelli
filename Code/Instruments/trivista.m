function varargout = trivista(Etage, fonction, varargin)
%   varargout = trivista(Etage, fonction, varargin)
%
%Fonction de controle du spectrometre Trivista
%
%Etage:     Indice du monochromateur conserne. 1, 2 ou 3
%fonction:  chaine de caracteres correspondant a la fonction voulue
%
%Position: Position en nanometres avec au plus 3 chiffres apres le point.
%
%varargout
%   pour être uniforme, les sorties de trivista.m devraient toujours être
%   en string (chaine de caractères)
%
%Fonctions principales:
% trivista('initialise')
% trivista(3, '?nm')
% trivista(3, 'goto', 500)
% trivista(3, 'grating', 2)
% trivista(3, '?mirror', 'exit-mirror')
% trivista('fermer')
%
%   trivista(Etage, '?blaze')                
%                       Retourne l'angle de mirroitement du réseau 
%                       actuel de l'etage selectionne. 
%   trivista('enregistre_configuration', [Fichier.m]) 
%                       Cree un Fichier.m qui contient toutes les commandes
%                       necessaires pour remettre le Trivista exactement
%                       dans le meme etat. Fichier.m est optionnel.                     
%   trivista('fermer')                  
%                       Ferme les ports de communications relatifs au
%                       TriVista.
%   trivista(Etage, '?g/mm')                
%                       Retourne le nombre de traits par millimetre du réseau 
%                       actuel de l'etage selectionne. 
%   trivista(Etage, 'goto', Position) 
%                       Deplace l'Etage a Position nm. Le deplacement se
%                       fait a la vitesse maximum.
%   trivista(Etage, 'goto_ordre', Position)       
%                       Deplace l'Etage a Position nm en tenant compte de
%                       l'ordre d'utilisation du reseau. Le deplacement se
%                       fait a la vitesse maximum.
%   trivista(Etage, 'grating', Reseau)    
%                       Change le reseau utilise. 
%                           1, 2, 3 reseaux de la premiere tourette
%                           4, 5, 6 reseaux de la deuxieme tourette
%                           7, 8, 9 reseaux de la troisieme tourette
%   trivista(Etage, '?grating')          
%                       Retourne le reseau utilise. 
%                           1, 2, 3 reseaux de la premiere tourette
%                           4, 5, 6 reseaux de la deuxieme tourette
%                           7, 8, 9 reseaux de la troisieme tourette
%   trivista(Etage, '?gratings')         
%                       Retourne la liste des reseaux installes. 
%   trivista('initialise', {[Adresses]})     
%                       Initialise les 3 etages du Trivista. Si Adresses
%                       n'est pas specifie on utilise 3, 4 et 5
%                       respectivement pour les etages 1, 2 et 3
%   trivista(Etage, 'microns', Fente, Ouverture)   
%                       Controle la largeur de la fente (en microns) 
%                           Fente:  'front-ent-slit'
%                                   'side-ent-slit'
%                                   'front-exit-slit'
%                                   'side-exit-slit'
%                       >trivista(2, 'microns', 'side-ent-slit', Largeur)
%                       >trivista(3, 'microns', 'side-ent-slit', Largeur)
%   trivista(Etage, '?microns', Fente)    
%                       Retourne la largeur de la fente (en microns) 
%                           Fente:  'front-ent-slit'
%                                   'side-ent-slit'
%                                   'front-exit-slit'
%                                   'side-exit-slit'
%                       >trivista(2, '?microns', 'side-ent-slit')
%                       >trivista(3, '?microns', 'side-ent-slit')
%   trivista(Etage, 'mirror', Miroir, Position)    
%                       Controle la configuration du miroir specifie 
%                           Miroir:     'exit-mirror'
%                                       'ent-mirror'
%                           Position:   'front' 
%                                      'side'
%   trivista(Etage, '?mirror', Miroir)    
%                       Retourne la configuration du miroir specifie 
%                           Miroir:     'exit-mirror'
%                                       'ent-mirror'
%   trivista(Etage, '?mir', Miroir)       
%                       Retourne la configuration du miroir specifie 
%                           Miroir:     'exit-mirror'
%                                       'ent-mirror'
%                           Sortie:     0: front
%                                       1: side
%   trivista(Etage, 'mono-?done')    
%                       Utilise avec trivista('>nm'..., determine si le
%                       monochromateur a atteind sa destination. Retourne 0
%                       si le deplacement n'est pas complet.  Retourne 1 si
%                       le deplacement est complet. 
%   trivista(Etage, 'mono-stop')     
%                       Utilise avec trivista('>nm'..., arrete le deplacement. 
%   trivista(Etage, 'nm', Position)   
%                       Deplace l'Etage a Position nm. Le deplacement se
%                       fait a la vitesse determinee par la commande
%                       'NM/MIN'. 
%   trivista(Etage, '?nm')           
%                       Retourne la position de l'Etage en nanometres
%   trivista(Etage, '?nm_ordre')                 
%                       Retourne la longueur d'onde en tenant compte de
%                       l'ordre utilise.
%   trivista(Etage, '>nm', Position)  
%                       Deplace l'Etage  a Position nm. Le deplacement se
%                       fait a la vitesse determinee par la commande
%                       'NM/MIN'. Cette variante de trivista('nm'... donne
%                       le controle a l'utilisateur tout de suite. On peut
%                       donc l'utiliser en combinaison avec
%                       trivista('?nm'... ou trivista('mono-?done'
%   trivista(Etage, 'nm/min', Vitesse)    
%                       Fixe la vitesse de deplacement du spectrometre en
%                       nanometres/minute. 
%   trivista(Etage, '?nm/min')       
%                       Retourne la vitesse de deplacement de l'etage 2 en
%                       nanometres par minute. 
%   trivista(Etage, 'ordre', ordre_demande)   
%                       Utilise l'etage selectionne a l'ordre_demande. 
%   trivista(Etage, '?ordre')                
%                       Retourne l'ordre d'utilisation de l'etage
%                       selectionne. 
%   trivista(Etage, 'turret', Tourette)   
%                       Specifie la tourette utilisee. 
%   trivista(Etage, '?turret')           
%                       Retourne la tourette utilisee. 
%
%Colin avril 2006
%11 octobre 2006
%   Colin
%   ajout de l'ordre d'utilisation des reseaux 'ordre', '?ordre', 
%   'goto_ordre', '?nm_ordre'.
%18 octobre 2006
%   Colin
%   Implementation de 'enregistre_configuration'.
%   Nouvelle fonction d'initialisation: on peut lancer l'initialisation
%   plusieurs fois sans probleme.
%2 décembre 2008
%   Colin
%   Ajouté les fonctions '?G/MM' et '?BLAZE'
%15 septembre 2014
%   Colin
%   Ajoute les fonctions 'MONO-EESTATUS', 'MODEL', 'SERIAL', 'MONO-RESET', 'HELLO', 'INIT-OFFSET'

%Adresse des port COM des 3 monochromateurs
% A ajuster
Adresse_TriVistaEtage1 = 4;
Adresse_TriVistaEtage2 = 5;
Adresse_TriVistaEtage3 = 3;

global TriVista_Etage1
global TriVista_Etage2
global TriVista_Etage3
persistent Trivista_Etage1_Ordre
persistent Trivista_Etage2_Ordre
persistent Trivista_Etage3_Ordre

%patch pour les fonction que ne prennent pas d'etage en parametre
switch upper(Etage)
case {'INITIALISE', 'FERMER', 'ENREGISTRE_CONFIGURATION'}
    if nargin > 1
        varargin = {fonction varargin{:}};
    end
    fonction = Etage;
case {1, 2, 3}
    %OK
otherwise
    disp('Erreur: l''etage selectionne doit etre 1, 2 ou 3.')
end

switch upper(fonction)
case 'INITIALISE'  
    if nargin > 2
        nouvel_argument = varargin{1};
    else
        nouvel_argument = [Adresse_TriVistaEtage1 Adresse_TriVistaEtage2 Adresse_TriVistaEtage3];
    end
    disp('     Initialisation du spectrometre TriVista')
     TriVista_Etage1 = initialise_TriVista(nouvel_argument(1));
     TriVista_Etage2 = initialise_TriVista(nouvel_argument(2));
     TriVista_Etage3 = initialise_TriVista(nouvel_argument(3));
     if isempty(Trivista_Etage1_Ordre)
        Trivista_Etage1_Ordre = 1;
     end
     if isempty(Trivista_Etage2_Ordre)
        Trivista_Etage2_Ordre = 1;
     end
     if isempty(Trivista_Etage3_Ordre)
        Trivista_Etage3_Ordre = 1;
     end
case 'FERMER'  
    fclose(TriVista_Etage1)
    fclose(TriVista_Etage2)
    fclose(TriVista_Etage3)
case {'GOTO', 'NM', '>NM', 'NM/MIN', 'GRATING', 'TURRET'}
    %Fonctions de controle
    %Fonctions demandant 1 parametre
    %Fonctions qui s'appliquent a un etage particulier
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    Parametre = varargin{1}; %indice du spectrometre a utiliser
    if isnumeric(Parametre)
        Parametre = num2str(Parametre);
    end
    %disp([Parametre ' ' fonction char(13)  char(10)])
    fprintf(Monochromateur, [Parametre ' ' fonction char(13)  char(10)]);
    attendre_trivista(Monochromateur)
case {'?NM', '?NM/MIN', 'MONO-?DONE', '?GRATING', '?GRATINGS', '?TURRET'}
    %Fonctions de diagnostic
    %Fonctions demandant aucun parametre
    %Fonctions retournant une chaine de caracteres
    %Fonctions qui s'appliquent a un etage particulier   
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    fprintf(Monochromateur, [fonction char(13)]);
    pause(.05)
    while get(Monochromateur, 'BytesAvailable')<1
        pause(.15)
    end
    sortie = fread(Monochromateur, get(Monochromateur, 'BytesAvailable'));
    sortie = nettoyer_chaine(sortie, fonction);
    switch upper(fonction)
        case '?GRATING'
            sortie = strrep(sortie, ' ', '');
    end
    varargout{1} = sortie;
case {'MONO-EESTATUS', 'MODEL', 'SERIAL'}
    %Fonctions de diagnostic
    %Fonctions demandant aucun parametre
    %Fonctions retournant une chaine de caracteres
    %Fonctions qui s'appliquent a un etage particulier   
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    fprintf(Monochromateur, [fonction char(13)]);
    pause(.5)
    while get(Monochromateur, 'BytesAvailable')<1
        pause(.1)
    end
    sortie = fread(Monochromateur, get(Monochromateur, 'BytesAvailable'));
    sortie = nettoyer_chaine(sortie, fonction);
    switch upper(fonction)
        case '?GRATING'
            sortie = strrep(sortie, ' ', '');
    end
    varargout{1} = sortie;
case {'MONO-RESET', 'HELLO'}
    %Fonctions de controle
    %Fonctions demandant aucun parametre
    %Fonctions qui s'appliquent a un etage particulier   
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    fprintf(Monochromateur, [fonction char(13)]);
case {'INIT-OFFSET'}
    %Fonctions de controle speciale
    %Fonctions demandant 0/1 parametre pour une lecture/controle
    %Fonction qui s'applique a un etage particulier
    reseau = varargin{1};  % 1, 2, 3
    turret = varargin{2};  % 1, 2, 3
    indiceReseau = reseau+(turret-1)*3;  % 1, 2, 3, 4, 5, 6, 7, 8, 9
    if nargin == 4 %lecture
        str = trivista(Etage,'MONO-EESTATUS');
        searchStr = 'offset';
        i = strfind(str, searchStr);  %debut de la ligne relative au offset
        j = strfind(str(i:end),13);  %fin de la ligne relative au offset
        out = str(i+length(searchStr):i+j-2);  %extrait la ligne relative au offset tout en enlevant "offset"
        out = str2num(out);
        out = out(indiceReseau);  %retourne seulement le reseau demande
        varargout{1} = out;
    elseif nargin == 5  %ecriture
        Parametre = varargin{3};  % offset du reseau
        if isnumeric(Parametre)
            Parametre = [num2str(Parametre) '.'];
        end
        Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
        strToWrite = [Parametre ' ' num2str(indiceReseau-1) ' ' fonction char(13)  char(10)];  % indiceReseau-1 vient du fait que l'indice du reseau est "zero based" dans le trivista
        fprintf(Monochromateur, strToWrite);

        %eval(['Trivista_Etage' num2str(Etage) '_Ordre = ' Parametre ';'])
        varargout{1} = trivista(Etage, fonction, reseau, turret);
    end
case {'?MIRROR', '?MIR', '?MICRONS'}
    %Fonctions de diagnostic
    %Fonctions demandant 1 parametre
    %Fonctions retournant une chaine de caracteres
    %Fonctions qui s'appliquent a un etage particulier   
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    Parametre = varargin{1}; %indice du spectrometre a utiliser
    if isnumeric(Parametre)
        Parametre = num2str(Parametre);
    end
    %disp(char([Parametre ' ' fonction char(13)]))
    fprintf(Monochromateur, [Parametre ' ' fonction char(13)]);
    pause(.05)
    while get(Monochromateur, 'BytesAvailable')<1
        pause(.1)
    end
    sortie = fread(Monochromateur, get(Monochromateur, 'BytesAvailable'));
    %disp(char(sortie'))
    varargout{1} = nettoyer_chaine(sortie, fonction) ;
case {'MIRROR', 'MICRONS'}
    %Fonctions de controle
    %Fonctions demandant 2 parametres
    %Fonctions qui s'appliquent a un etage particulier
    Monochromateur = eval(['TriVista_Etage' num2str(Etage)]);
    Parametre1 = varargin{1}; %indice du spectrometre a utiliser
    Parametre2 = varargin{2}; %indice du spectrometre a utiliser
    if isnumeric(Parametre1)
        Parametre1 = num2str(Parametre1);
    end
    if isnumeric(Parametre2)
        Parametre2 = num2str(Parametre2);
    end
    fprintf(Monochromateur, [Parametre1 ' ' Parametre2 ' ' fonction char(13)]); 
    attendre_trivista(Monochromateur)
case {'ORDRE'}
    %Fonctions de controle speciales
    %Fonctions demandant 0/1 parametre pour une lecture/controle
    %Fonctions qui s'appliquent a un etage particulier
    if nargin == 2 %lecture
        out = num2str(eval(['Trivista_Etage' num2str(Etage) '_Ordre']));
        if isempty(out)
            out = '1';
            eval(['Trivista_Etage' num2str(Etage) '_Ordre = ' out ';'])
        end
        varargout{1} = out;
    else  %ecriture
        Parametre = varargin{1}; %indice du spectrometre a utiliser
        if isnumeric(Parametre)
            Parametre = num2str(Parametre);
        end
        eval(['Trivista_Etage' num2str(Etage) '_Ordre = ' Parametre ';'])
        varargout{1} = trivista(Etage, fonction);
    end
case {'?ORDRE'}
    varargout{1} = trivista(Etage, fonction(2:end));
case {'GOTO_ORDRE'}
    %Fonction de controle speciale qui tient compte d'une eventuelle
    %utilisation a un ordre superieur (`a 1) des reseaux.
    %Fonction demandant 1 parametre
    %Fonction qui s'applique a un etage particulier
    fonction = strrep(upper(fonction), '_ORDRE', '');
    Parametre = varargin{1}; %indice du spectrometre a utiliser
    if isnumeric(Parametre)
        Parametre = num2str(Parametre);
    end
    Parametre = num2str(str2num(Parametre)*str2num(trivista(Etage, '?ordre')));
    trivista(Etage, fonction, Parametre);
    %disp(['trivista(' num2str(Etage) ', ' fonction ', ' Parametre ')'])
case {'?NM_ORDRE'}
    %Fonction de diagnostic speciale qui tient compte d'une eventuelle
    %utilisation a un ordre superieur (`a 1) des reseaux.
    %Fonctions ne demandant aucun parametre
    %Fonctions retournant une chaine de caracteres
    %Fonctions qui s'appliquent a un etage particulier 
    fonction = strrep(upper(fonction), '_ORDRE', '');
    varargout{1} = num2str( str2num(trivista(Etage, fonction))/str2num(trivista(Etage, 'ordre')) ) ;
case {'?G/MM', '?BLAZE'}
    %Retourne le nombre de traits par mm pour le réseau actuel
    %Fonction ne demandant aucun parametre
    %Fonctions retournant une chaine de caracteres
    %Fonctions qui s'appliquent a un etage particulier 
    a = trivista(Etage, '?gratings');
    i = str2num(trivista(Etage, '?grating'));
    k = strfind(a, char(10));
    param = strrep(strrep(a(k(i)+1:k(i+1)-1), '  ', ' '), '  ', ' '); % ligne caractérisant le système
    switch upper(fonction)
        case '?G/MM'
            j=strfind(param, ' ');
            if length(j)<2 %très rarement (<10% des fois), cette commande plante
                %??? Index exceeds matrix dimensions.
                %
                %Error in ==> trivista at 311
                %varargout{1} = param(j(1)+1:j(2)-1);
                %cette commande sert à remédier à ça.
                warning('trivista.m: ''?G/MM'' Erreur detectee')
                a
                i
                k
                j
                a = trivista(Etage, '?gratings');
                i = str2num(trivista(Etage, '?grating'));
                k = strfind(a, char(10));
                param = strrep(strrep(a(k(i)+1:k(i+1)-1), '  ', ' '), '  ', ' '); % ligne caractérisant le système
                j=strfind(param, ' ');
            end
            varargout{1} = param(j(1)+1:j(2)-1);
        case '?BLAZE'
            j=strfind(param, 'blz= ');
            varargout{1} = param(j+5:end-1);
    end
case {'INSTALL', 'SELECT-GRATING', 'G/MM', 'BLAZE', 'UNISTALL', '<GOTO>', '<NM>'}
    disp('Commande non implementee.')
case 'ENREGISTRE_CONFIGURATION'
    if nargin==1 
        [fichier, nom_repertoire, FilterIndex] = uiputfile('.m', 'Fichier de sauvegarde de la configuration du Trivista');
        fichier = [nom_repertoire fichier];
    else
        fichier = varargin{1};
    end
    if ~strcmp(fichier(end-1:end), '.m')
        fichier = [fichier '.m'];
    end
    fid = fopen(fichier, 'w');
    
    fprintf(fid, ('%% Fichier de configuration du Trivista \n'));
    fprintf(fid, (['%% 	genere par trivista(''enregistre_configuration'')\n ']));
    fprintf(fid, (['%% 	enregistre le ' datestr(now) '\n']));
    fprintf(fid, 'trivista(''initialise'');\n');
    chaine = { ...
            '?nm' 'goto'; ...
            '?ordre', 'ordre'; ...
            '?grating', 'grating'; ...
            '?nm/min' 'nm/min'; ...
            '?turret', 'turret'; ...
            };
    for etage = 1:3
        for i=1:size(chaine, 1)
            fprintf(fid, (['trivista(' num2str(etage) ', ''' chaine{i, 2} ''', ' trivista(etage, chaine{i, 1}) ');\n']));
        end
        fprintf(fid, ('%%  \n'));
    end
    
    chaine = { ...
            '?nm_ordre' 'goto_ordre'; ...
            };
    for etage = 1:3
        for i=1:size(chaine, 1)
            fprintf(fid, (['%%trivista(' num2str(etage) ', ''' chaine{i, 2} ''', ' trivista(etage, chaine{i, 1}) ');\n']));
        end
    end
        
    chaine = {'?mirror' 'mirror'};
    chaine2 = {'ent-mirror';'exit-mirror'};
    for etage = 1:3
        for i=1:size(chaine, 1)
            for j=1:size(chaine2, 1)
                fprintf(fid, (['trivista(' num2str(etage) ', ''' chaine{i, 2} ''', ''' chaine2{j, 1} ''', ''' trivista(etage, chaine{i, 1}, chaine2{j, 1}) ''');\n']));
            end
        end
    end
    fprintf(fid, ('%%  \n'));

    chaine = {'?microns' 'microns'};
    chaine2 = {'side-ent-slit'};
    for etage = 2:3
        for i=1:size(chaine, 1)
            for j=1:size(chaine2, 1)
                fprintf(fid, (['trivista(' num2str(etage) ', ''' chaine{i, 2} ''', ''' chaine2{j, 1} ''', ''' trivista(etage, chaine{i, 1}, chaine2{j, 1}) ''');\n']));
            end
        end
    end
    fprintf(fid, ('%%  \n'));
    
    out = fclose(fid);
    switch out
    case 0
        disp('Configuration du TriVista enregistree ')
        disp(['  avec succes dans le fichier: ' fichier])
    case -1
        disp(['Erreur dans l''enregistrement de la configuration du TriVista' ])
    end
otherwise 
    disp('fonction pas encore implementee')
end

function attendre_trivista(Monochromateur)
%attend que le spectro ait fini de faire le changement demande
N = 0;
pause(.02)
while N < 2
    pause(0.02)
    M = get(Monochromateur, 'BytesAvailable');
    if M > 0
        b = fread(Monochromateur, M);
        b = char(b');
        c = strfind(b, 'ok');
        NN = length(c);
        N = N + NN;
    end
end

function out = nettoyer_chaine(in, fonction)
out = upper(char(in'));
out = strrep(out, 'OK', '');
out = strrep(out, 'NM/MIN ', '');
out = strrep(out, '?', '');
out = strrep(out, 'NM ', '');
out = strrep(out, 'UM', '');
out = strrep(out, 'SIDE-', '');
out = strrep(out, 'ENT-', '');
out = strrep(out, 'FRONTE-', '');
out = strrep(out, 'EXIT-', '');
out = strrep(out, 'SLIT ', '');
out = strrep(out, 'GRATING ', '');
out = strrep(out, 'TURRET ', '');
out = strrep(out, 'MIRROR ', '');
out = strrep(out, 'MIR ', '');
out = strrep(out, 'MICRONS ', '');
out = strrep(out, 'MONO-DONE ', '');
out = strrep(out, fonction, '');
out = lower(deblank(out));

function TriVista_Etage = initialise_TriVista(addresse)
global TriVista_Etage1
global TriVista_Etage2
global TriVista_Etage3
if isnumeric(addresse)
    addresse = num2str(addresse);
end
TriVista_Etage = instrfind('Port', ['COM' addresse ''], 'Status', 'open');
if isempty(TriVista_Etage)
    TriVista_Etage = serial(['COM' addresse]);
    set(TriVista_Etage, 'terminator', 'CR');
    fopen(TriVista_Etage);
else
    %disp(['     Port COM' addresse ' deja ouvert.'])
end


