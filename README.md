# Super_toc2cue
Script permettant de convertir un fichier .toc en fichier .cue pour les CD audio.

## Fonctionnalitées :
- Récupération des métadonnées, titre de l'album, nom de l'artiste, nom de chaque piste audio...
- Calcul des valeurs pour INDEX 01 et 00.

## Méthode de calcul des valeurs pour INDEX
INDEX 00 : Début globale de la piste audio.
INDEX 01 : Début réel de la piste audio.
START : Transition.

Récupération des valeurs
Dans le fichier toc on retrouve les lignes suivantes :
```
FILE "/home/daniel/My_cd_Backup_020325142619_test/image.bin" 02:31:30 03:48:73
START 00:00:09
```
La première aleur de la directive FILE c'est le nom di fichier binaire puis la deuxième c'est le début global de la piste audio puis la dernière c'est la durée de la piste audio.
Pour la valeur START c'est la transition.

INDEX 00 = Début global 
INDEX 01 = INDEX 00 + Transition(START)

Exemple :
INDEX 00 = 02:31:30
INDEX 01 = 02:31:30 + 00:00:09 


Pour calculer INDEX 00 et 01 quand il y a pas de valeur START
INDEX 00 = 
INDEX 01 =

