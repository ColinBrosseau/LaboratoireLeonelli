Fichiers source (LaTeX) pour produire le procédurier du laboratoire

# Paquets nécessaires pour la compilation avec Latex
- texlive-latexextra (cclicenses.sty, enumitem.sty, titletoc.sty, lipsum.sty)
- texlive-bibtexextra (biblatex.sty)
- texlive-pictures (smartdiagram.sty)
- biber

# Génération du fichier PDF

## Initialisation du style

(À faire une seule fois)

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

- HydraHarp
  - [X] lien vers les spécifications techniques
  - [X] lien vers le logiciel
  - utilisation avec Matlab:
    - [ ] explication de la bibliothèque nécessaire
    - [ ] trivista_hydra: code et procédure
  - [ ] utilisation du logiciel propriétaire
- Modulateurs Acousto-optiques
  - [ ] Ajout documents scannées
- Camera Pixis
  - [ ] Détails de la procédure d'installation
- Ordinateur U1000
  - [ ] Installation des logiciels
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