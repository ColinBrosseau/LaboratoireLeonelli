Fichiers source (LaTeX) pour produire le procédurier du laboratoire

# Génération du fichier PDF

## Initialisation du style

Nécessaire une seule fois

-   makeindex procedurierLeonelli.idx -s StyleInd.ist

## Génération du PDF
Pour générer un fichier PDF à partir des fichiers sources

Manière classique:
-	pdflatex procedurierLeonelli.tex

En utilisant make:
-	make

# Contenu de ce répertoire


|Fichier|Fonction|
|:---------|:----------|
|Image (répertoire)| Contient les images contenues dans le procédurier|
|LICENCE| Licence du document|
|matlab-prettifier.sty| Mise en forme des codes Matlab|
|Makefile| Fichier pour la compilation automatique (make)|
|procedurierLeonelli.tex| Texte du document|
|README.md| (Ce fichier) Instructions de base|
|structure.tex| Mise en page du document|
|StyleInd.ist| Fichier de style|

## Todo
- Bomem
  - [X] Paramètres optimaux pour les différents détecteurs
  - [X] Procédure pour tranférer les données
    - [X] disquettes
    - [X] réseau (attention de débrancher après)
  - [X] procédure de démarage
  - [X] interprétation de % (saturé = 0%)
  - [ ] débloquer manuellement le diaphragme
- Feuille de temps
  - [X] Modèle de feuille d'utilisation du laboratoire (se baser sur le modèle de Ghaouti)
- HydraHarp
  - [ ] lien vers les spécifications techniques
  - [ ] lien vers le logiciel
  - [ ] utilisation avec Matlab: explication de la bibliothèque nécessaire
  - [ ] utilisation du logiciel propriétaire
