# Super_toc2cue

Script permettant de convertir un fichier `.toc` en fichier `.cue` pour les CD audio.

## Pourquoi ce script ?

Le format `.toc` est utilisé par `cdrdao` pour décrire la structure d'un CD, mais il n'est pas toujours compatible avec certains logiciels de lecture et d'extraction audio. Ce script permet donc de convertir un fichier `.toc` en `.cue`, un format plus largement reconnu.

## Fonctionnalités

- Récupération des métadonnées : titre de l'album, nom de l'artiste, noms des pistes audio...
- Calcul automatique des valeurs pour `INDEX 01` et `INDEX 00`.

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

On utilise ensuite le script pour obtenir un fichier `.cue` à partir du fichier `.toc` :

```bash
./super_toc2cue.bash image.toc
```

Affichage attendu :
```bash
Conversion du fichier image.toc vers image.cue terminée !
```

Une fois les métadonnées récupérées, on peut extraire les pistes audio avec :

```bash
cdparanoia -B --verbose --never-skip=5 --log-summary
```

Et si une conversion en FLAC est nécessaire :

```bash
flac *.wav --preserve-modtime --best --delete-input-file
```

## Méthode de calcul des valeurs pour INDEX

- **INDEX 00** : Début global de la piste audio.
- **INDEX 01** : Début réel de la piste audio.
- **START** : Transition entre les pistes.

### Récupération des valeurs

Dans le fichier `.toc`, on retrouve les lignes suivantes :

```
FILE "/home/daniel/My_cd_Backup_020325142619_test/image.bin" 02:31:30 03:48:73
START 00:00:09
```

- La première valeur de la directive `FILE` est le nom du fichier binaire.
- La deuxième valeur est le **début global** de la piste audio.
- La troisième valeur est la **durée de la piste audio**.
- `START` représente la transition.

### Calcul des INDEX

```text
INDEX 00 = Début global
INDEX 01 = INDEX 00 + Transition (START)
```

**Exemple :**
```
INDEX 00 = 02:31:30
INDEX 01 = 02:31:30 + 00:00:09
```

**Cas particulier** :
- Si la ligne `START` est absente ou vaut `0`, seul `INDEX 01` est affiché.

### Explication des valeurs temporelles

Le format utilisé suit la norme Red Book des CD audio :
- Les **deux premiers chiffres** correspondent aux minutes (de 0 à 99).
- Les **deux suivants** correspondent aux secondes (de 0 à 59).
- Les **deux derniers** correspondent aux frames (de 0 à 74).

⚠️ **75 frames = 1 seconde**

### Exemple détaillé

Extrait d’un fichier `.toc` pour la piste 7 :
```text
// Track 7
TRACK AUDIO
NO COPY
NO PRE_EMPHASIS
TWO_CHANNEL_AUDIO
ISRC "FRZ111200682"
CD_TEXT {
  LANGUAGE 0 {
    TITLE "Pourquoi vous ?"
    PERFORMER ""
  }
}
FILE "/home/daniel/My_cd_Backup_020325142619_test/image.bin" 21:45:59 03:32:31
START 00:00:26
```

Calcul des valeurs :
```text
INDEX 00 = 21:45:59
START = 00:00:26
INDEX 01 = INDEX 00 + START
INDEX 01 = 21:45:59 + 00:00:26
```

Décomposition du calcul :
- Addition des frames : **59 + 26 = 85**
- Comme 85 dépasse 75, on soustrait 75 et on retient 1 seconde : **85 - 75 = 10 frames**
- Addition des secondes avec la retenue : **45 + 0 + 1 = 46 secondes**
- Addition des minutes : **21 + 0 = 21 minutes**

✅ **Résultat final : `INDEX 01 = 21:46:10`**

## Reste à faire

- Ajouter une fonction de correction automatique en cas de valeurs incohérentes, en utilisant la durée de la piste comme référence.

## Avertissements

- Ce script est conçu pour les CD audio et pourrait ne pas fonctionner correctement avec d'autres types de disques.
- Vérifiez toujours les fichiers générés avant de les utiliser.

