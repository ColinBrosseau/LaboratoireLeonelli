function trivista_hydra(varargin)
%   trivista_hydra(nom_parametre,valeur,...)
%   
%   ex.: trivista_hydra('l',[400:10:450], 't',30, 'dat', 'o',1, 'r',64, 'f','fichier_de_la_mesure') 
%       Chaque accumulation dure 30 secondes. Cree des fichiers .dat
%       (ascii) en plus des .mat. Utilise l'ordre 1 du spectrometre.
%       Utilise une resolution de 64 ps. Sauve dans les fichiers
%       fichier_de_la_mesure.mat et fichier_de_la_mesure.dat
%
%Cette fonction controle uniquement l'etage 3 du spectrometre. On suppose
%donc que le détecteur y est connecté.
%L'utilisateur est responsable de regler prealablement le spectrometre
%(mirroirs, fentes, reseau, etc) 
%
%-----------------------------------
%  nom_parametre           valeur
%-----------------------------------
%'lambda', 'l'          [Vecteur de nombres] 
%                       Obligatoire
%                       Plage de longueur d'onde a regarder (en nm)
%                       soit lambda ou [lambda initial: pas: lambda final]                        
%
%'temps', 't'           [Nombre]
%                       Defaut: 1
%                       Duree de chaque acquisition (s)
%
%'ordre','o'            [Entier]
%                       Defaut: 1
%                       Ordre d'utilisation du reseau 3
%
%'initialise_pas'       [Aucune valeur]
%                       N'initialise pas les appareils
%
%'resolution','r'       [Entier, puissance de 2]
%                       Defaut: 1
%                       Resolution du HydraHarp (entre 1 et 1024 ps)
%
%'fichier', 'f'         [Chaine de caractere]
%                       Obligatoire
%                       On ajoute automatiquement un .mat ou .dat
%
%'balayage','b'         [Aucune valeur]
%                       Effectue un balayage en longueur d'onde et obtient
%                       le taux de comptage des entrees. Donne donc un
%                       spectre approximatif non-resolu dans le temps
%                       Le parametre numerique indique sur quel nombre de 
%                       mesures du taux de comptage est effectue la moyenne
%
%'dat'                  [Aucune valeur]
%                       Sauvegarde les données en .dat en plus du .mat
%
%'ecrase'               [0, 1]
%                       Defaut: 0
%                       Deactive la protection anti-ecrasement des fichiers
%
% 'SD0'                 [Entier]
%                       Defaut: 10
%                       SyncCFDZeroX (en mV)
% 'SDL'                 [Entier]
%                       Defaut: 60
%                       SyncCFDLevel  (en mV)
%
% 'IDO'                 [Entier]
%                       Defaut: 10
%                       InputCFDZeroX  (en mV)
%
% 'IDL'                 [Entier]
%                       Defaut: 600
%                       InputCFDLevel  (en mV)
%
% 'SD'                  [Entier]
%                       Defaut: 4
%                       sync divider
%
%-----------------------------------
%les parametres lambda et fichier sont obligatoires.
%Pour un balayage, seulement lambda est obligatoire

% == Historique des modifications==
%
%Fevrier 2011
%   Nicolas Gauthier 
%   Base sur la fonction de Colin trivista_tn7200pico.m
%Modifie par Pascal Gregoire Mai 2011
%30 nov 2012
%   Colin
%   Introduction d'un 'try' permettant d'utiliser cette fonction sans avoir
%   absolument besoin du picoamperemetre
%19 avril 2013
%   Colin
%   Empeche l'ecrasement accidentel des fichiers
%   (fonction CheckFilename)

%variables globales qui servent pour les mesures avec differents lambdas
global courant
global hs
global lam

%Variables par défaut
NOM_FICHIER = '';
INITIALISE = 1 ; %Il y a initialisation
Ordre_Trivista=1; % Ordre du spectrometre
temps = 1; %temps d'acquisition en seconde
lambda=-1; 
resolution=1; %en ps
balayage=-1; %Pas de balayage, on effectue une mesure résolue dans le temps
fichier_dat=0; %Pas de sauvegarde en .dat, juste en .mat
global ecrase;
ecrase = 0;
SyncCFDZeroX  = 10;     %en mV
SyncCFDLevel  = 60;     %en mV
InputCFDZeroX = 10;     %en mV
InputCFDLevel = 600;     %en mV
SyncDiv       = 4;       %permet d'avoir une plus grande plage de temps
%Les autres paramètre par défaut conscernant hhdefine sont au début de la
%fonction hydra.m


%lit tous les parametres passes en option
n_arguments = -nargin(mfilename); %nombre d'arguments incluant varargin
A = varargin;
N_varargin = nargin-n_arguments+1;
i=1;
while i <= N_varargin
    switch upper(A{i}) 
        case {'FICHIER','F'}
            NOM_FICHIER = A{i+1};  
            i = i + 2;
        case {'T','TEMPS'}
            temps = A{i+1}; 
            i = i + 2;
        case {'LAMBDA','L'}
            lambda = A{i+1}; 
            i = i + 2;
        case {'ORDRE','O'}
            Ordre_Trivista = A{i+1}; 
            i = i + 2;
        case {'RESOLUTION','R'}
            resolution = A{i+1}; 
            i = i + 2;
        case 'INITIALISE_PAS'
            INITIALISE = 0;
            i = i + 1;
        case {'BALAYAGE','B'}
            balayage=1;
            %le temps par mesure se defini par 't'
            %NbMoyenne=A{i+1};  % ???nombre de secondes par point
            i = i + 1;
        case 'DAT'
            fichier_dat=1;
            i = i + 1;
        case 'ECRASE'
            ecrase=1;
            i = i + 1;
        case {'SD0','SDO'}
            SyncCFDZeroX = A{i+1}; 
            i = i + 2;
        case 'SDL'
            SyncCFDLevel = A{i+1}; 
            i = i + 2;
        case {'ID0','IDO'}
            InputCFDZeroX = A{i+1}; 
            i = i + 2;
        case 'IDL'
            InputCFDLevel = A{i+1}; 
            i = i + 2;
        case 'SD'
            SyncDiv = A{i+1}; 
            i = i + 2;
        otherwise
            %Mauvais parametre
            i = i + 1;
    end
end

%Vérification que les paramètres obligatoires ont été rentrés
if strcmp(NOM_FICHIER,'') && balayage == -1
    fprintf('\nLa routine a ete arretee car il n''y a aucun nom de fichier.\n');
    return;
end
if lambda == -1 %On s'assure que la longueur d'onde a été rentrée en paramètre (obligatoire)
    fprintf('\nLa routine a ete arretee car il n''y a pas de longueur d''onde.\n');
    return;
end
%Avertissement pour une difference entre les versions a Nicolas et a Pascal
if length(lambda) == 3 && lambda(2)<lambda(1)
    fprintf('Attention: lambda s''écrit maintenant [l_initial:pas:l_final] et non [l_initial,pas,l_final]\n')
    pause(15)
end
    
if INITIALISE %si l'on veut une initialisation des appareils
    disp('Initialisation des appareils')
    %initialisation de la carte GPIB
    initialise_gpib 
    trivista('initialise')
    hydra('initialise')
    try
        pico6485('initialisation')
    catch
        disp('')
        disp(' >>> Erreur d''initialisation du picoamperemetre.')
        disp(' >>> Mesure faite sans picoamperemetre.')
        disp('')
    end
end

%On met l'unite 3 du spectrometre à l'ordre desire
if Ordre_Trivista~= -1
    trivista(3,'ordre',Ordre_Trivista);
else
    trivista(3,'ordre',1);
end

%Ajustement de la résolution et des discriminateurs (on modifie les
%parametres par defaut)
hydra('modifier','r',resolution,'SDO',SyncCFDZeroX,'SDL',SyncCFDLevel,'IDO',InputCFDZeroX,'IDL',InputCFDLevel,'SD',SyncDiv)
    
switch balayage

    %%%%%%%%%%%
    %pas de balayage, on effectue une mesure résolue dans le temps
    case -1
        %if balayage == -1 %pas de balayage, on effectue une mesure résolue dans le temps
        %On initialise l'interface graphique pour l'intensité du laser
        clf,figure(1)
        hs=uicontrol('style','radiobutton','string','stop');

        %fichier=strcat(NOM_FICHIER,'_LXXX.XX','.mat');
        fichier=strcat(NOM_FICHIER,'.mat');

        disp(' ')
        disp('--- Parametres ------')
        disp(['FICHIER : ' fichier])
        disp(['Temps : ' num2str(temps) ' s'])
        if length(lambda)>1 %On affiche seulement pour plusieurs longueurs d'onde, la longueur d'onde comme telle est affichée plus loin
            disp(['Lamda initial(nm) : ' num2str(lambda(1))])
            disp(['Lamda final(nm) : ' num2str(lambda(length(lambda)))])
            disp(['Pas(nm) : ' num2str(lambda(2)-lambda(1))])
        end
        disp(['ORDRE : ' num2str(Ordre_Trivista)])
        disp(['SDL : ' num2str(SyncCFDLevel)])
        disp(['IDL : ' num2str(InputCFDLevel)])
        disp('---------------------')
        disp(' ')
        disp('*****************************************')
        disp(['   Debut de la mesure     ' fichier])
        disp('*****************************************')

        %boucle sur les differentes longueurs d'onde
        for lam=lambda % Attention, le compteur lam est une variable globale utilise par la fonction hydra_mesure
            courant=[];
            disp(' ')
            disp('     ---------------------')
            disp(['       Lamda (nm) : ' num2str(lam)])
            disp('     ---------------------')

            trivista(3,'goto_ordre',num2str(lam));
            %donne un nom de fichier selon lambda
            nom_fichier=strcat(NOM_FICHIER,sprintf('_L%g',lam),'.mat');
            CheckFilename(nom_fichier,ecrase);
            
            %mesure
            if fichier_dat==1
                hydra('mesure','f',nom_fichier,'t',temps,'dat');
            else
                hydra('mesure','f',nom_fichier,'t',temps);
            end

            %on arrete le programme si le bouton stop est pese
            stop=get(hs,'value');
            if stop==1
                break
            end
        end
        %end
        
    %%%%
    %balayage, on mesure un spectre approximatif non-resolu dans le temps
    case 1 
        nom_fichier = strcat(NOM_FICHIER,'.mat');
        CheckFilename(nom_fichier,ecrase);
        %if balayage==1 %balayage, on mesure un spectre approximatif non-resolu dans le temps
        l=length(lambda);
        Ch1Rate=zeros(1,l);
        Ch2Rate=zeros(1,l);
        fig3=figure(3);
        NbMoyenne = ceil(temps);
        set(fig3,'doublebuffer','on') %Empêche le clignotement de la figure
        for i=1:l
            title({[num2str(lambda(i)) ' nm']
                ['Il reste ',num2str((length(lambda)-i+1)*NbMoyenne),' s à la mesure']})
            ylabel('Comptes par seconde')
            xlabel('Longueur d''onde (nm)')
            warning('off')
            legend('Ch1','Ch2');
            warning('on')
            trivista(3,'goto_ordre',num2str(lambda(i)));
            Ch1=zeros(1,NbMoyenne);
            Ch2=zeros(1,NbMoyenne);
            for j=1:NbMoyenne
                [SyncRate,Ch1(j),Ch2(j)]=hydra('taux');
                pause(1);
            end
            Ch1Rate(i)=sum(Ch1)/NbMoyenne;
            Ch2Rate(i)=sum(Ch2)/NbMoyenne;
            if i==1%On crée le graphique pour le premier point
                p=plot(lambda(1),Ch1Rate(1),'b.',lambda(1),Ch2Rate(1),'r.');
                set(gca,'xlim',[lambda(1) lambda(end)]);
                drawnow
            else% On modifie le graphique pour les autres points
                set(p(1),'xdata',lambda(1:i),'ydata',Ch1Rate(1:i));
                set(p(2),'xdata',lambda(1:i),'ydata',Ch2Rate(1:i));
                set(gca,'xlim',[lambda(1) lambda(end)]);
                drawnow;
            end
            title('Mesure terminee')
            save(nom_fichier, 'lambda', 'Ch1Rate','Ch2Rate')
        end
end
hydra('stop')

function CheckFilename(filename,ecrase)
%verifie si le fichier de sortie existe deja
if exist(filename,'file') && (ecrase ==0)
    error('Fichier existant. Ecrasement interdit.')
end



