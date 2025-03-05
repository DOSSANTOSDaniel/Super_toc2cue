# Super_toc2cue
Script permettant de convertir un fichier .toc en fichier .cue pour les CD audio.

## Fonctionnalitées :
- Récupération des métadonnées, titre de l'album, nom de l'artiste, nom de chaque piste audio...
- Calcul des valeurs pour INDEX 01 et 00.

## Cas d'utilisation
Après la récupération d'un CD audio avec cette commande :
```bash
    cdrdao read-cd \
    --read-raw \
    --driver generic-mmc:0x20000 \
    --device /dev/sr0 \
    --datafile image.bin \
    --eject \
    --paranoia-mode 1 -v 2 image.toc
```
On utilise ici le script pour obtenir un fichier cue à partir du fichier toc.
```bash
daniel@c70-b:~/Nextcloud/Partage/TP_Missions/FFMPEG/toc2cue$ ./super_toc2cue.bash image.toc 
Conversion du fichier image.toc vers image.cue terminée !
```
Une fois que nous avons récupéré toutes les métadonnées nécessaires on peut utiliser cette commande pour extraire les pistes audios :
```bash
cdparanoia -B --verbose --never-skip=5 --log-summary
```
Et si vous avez besoin de convertir en flac :
```bash
flac *.wav --preserve-modtime --best --delete-input-file
```

## Méthode de calcul des valeurs pour INDEX
- INDEX 00 : Début globale de la piste audio.
- INDEX 01 : Début réel de la piste audio.
- START : Transition.

Récupération des valeurs
Dans le fichier toc on retrouve les lignes suivantes :
```
FILE "/home/daniel/My_cd_Backup_020325142619_test/image.bin" 02:31:30 03:48:73
START 00:00:09
```
- La première valeur de la directive FILE c'est le nom du fichier binaire, puis la deuxième c'est le début global de la piste audio, puis la dernière c'est la durée de la piste audio.
- Pour la valeur START c'est la transition.
```
INDEX 00 = Début global 
INDEX 01 = INDEX 00 + Transition(START)
```
Exemple :
```
INDEX 00 = 02:31:30
INDEX 01 = 02:31:30 + 00:00:09 
```
Comprendre la valeur 00:00:00 :

- Les deux premiers chiffres correspondent aux minutes de 0 à 99.
- Les deux deuxièmes chiffres correspondent aux secondes de 0 à 59.
- Les deux derniers chiffres correspondent aux frames de 0 à 74.

Une fois que nous avons atteint 75 frames en ajoute une seconde et on réinitialise la valeurs des frames (75 frames = 1seconde).
