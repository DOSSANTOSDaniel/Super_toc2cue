#!/usr/bin/env bash

#--------------------------------------------------#
# Script_Name: super_toc2cue.bash
#
# Author:  'dossantosjdf@gmail.com'
#
# Date: 28/02/2025
# Version: 1.0
# Bash_Version: 5.2.32
#--------------------------------------------------#

# Vérifier si un argument est fourni
if [ $# -ne 1 ]; then
  echo "Il faut passer en argument un fichier toc !"
  echo "Usage: $0 fichier.toc"
  exit 1
fi

# Vérifier si c'est un fichier toc
if [[ -f "$1" ]]; then
  type_file="$(file --mime-type -b "$1")"
  if ! [[ "$type_file" == text/* ]]; then
    echo "Le fichier $1 n'est pas compatible !"
    exit 1
  fi
else
  echo "Le fichier $1 n'existe pas !"
  exit 1
fi

toc_file="$1"
cue_file="${toc_file%.toc}.cue"

# Extraire le nom du fichier bin
bin_file=$(grep -oP 'FILE "\K[^"]+' "$toc_file" | head -n 1)

# Extraire la valeur de CATALOG
catalog_info="$(grep -oP 'CATALOG "\K[0-9]{13}(?=")' "$toc_file" | head -n 1)"

# Vérifier si un fichier bin a été trouvé
if [ -z "$bin_file" ]; then
    echo "Aucun fichier bin trouvé dans le fichier toc !"
    exit 1
fi

# Fonction permettant de calculer les index
calculindex() {
  file_start="$1"
  start_track="$2"

  if [[ -n "$start_track" ]]; then
    index_00="$file_start"
    # Extraction des données
    IFS=':' read -r index_00_minutes index_00_seconds index_00_frames <<< "$index_00"
    IFS=':' read -r start_track_minutes start_track_seconds start_track_frames <<< "$start_track"
    # Calcul des frames (00 à 74)
    calcul_frames="$((${index_00_frames#0}+${start_track_frames#0}))"
    if [[ "$calcul_frames" -gt '74' ]]; then
      calcul_frames_rest="$((${calcul_frames#0}-75))"
      if [[ "$calcul_frames_rest" -eq '0' ]]; then
        calcul_frames='00'
        add_seconds='1'
      elif [[ "$calcul_frames_rest" -gt '0' ]]; then
        calcul_frames="$calcul_frames_rest"
        add_seconds='1'
      fi
    else
      calcul_frames="$calcul_frames"
      add_seconds='0'
    fi
    # Calcul des secondes (00 à 59)
    calcul_seconds="$((${index_00_seconds#0}+${start_track_seconds#0}+add_seconds))"
    if [[ "$calcul_seconds" -gt '59' ]]; then
      calcul_seconds_rest="$((${calcul_seconds#0}-60))"
      if [[ "$calcul_seconds_rest" -eq '0' ]]; then
        calcul_seconds='00'
        add_minutes='1'
      elif [[ "$calcul_seconds_rest" -gt '0' ]]; then
        calcul_seconds="$calcul_seconds_rest"
        add_minutes='1'
      fi
    else
      calcul_seconds="$calcul_seconds"
      add_minutes='0'
    fi
    # Calcul des minutes (00 à 99)
    calcul_minutes="$((${index_00_minutes#0}+${start_track_minutes#0}+add_minutes))"
    if [[ "$calcul_minutes" -gt '99' ]]; then
      echo "Les minutes dépassent 99, valeur calculée : $calcul_minutes"
      exit 1
    fi
    index_01="$(printf "%02d:%02d:%02d" "$calcul_minutes" "$calcul_seconds" "$calcul_frames")"
  else
    index_00="$file_start"
    index_01="$index_00"
    start_value="false"
  fi

  if [[ "$start_value" == 'false' ]]; then
    echo "    INDEX 01 $index_01"
  else
    echo "    INDEX 00 $index_00"
    echo "    INDEX 01 $index_01"
  fi
}

# Créer le fichier cue
# REM configuration globale ###
echo "REM COMMENT \"Ripped from original CD\"" > "$cue_file"
if [[ -n "$catalog_info" ]]; then
  echo "CATALOG $catalog_info" >> "$cue_file"
fi

# FILE configuration globale ###
if [[ -n "$bin_file" ]]; then
  echo "FILE \"$bin_file\" BINARY" >> "$cue_file"
else
  echo "Pas d'indications sur le fichier bin dans le fichier toc !"
  exit 1
fi

track_num=0
start_found=false

while IFS= read -r toc_line; do
  # TRACK et INDEX ###
  if [[ "$toc_line" =~ TRACK\ AUDIO ]]; then
    # Si une piste précédente n'a pas de ligne START
    if [[ "$track_num" -gt 0 && "$start_found" == false ]]; then
      calculindex "$begin_audio_track" "$track_transition" | grep 'INDEX 01' >> "$cue_file"
    fi
    # Incrémenter track_num permet de détecter la piste courante
    ((track_num++))
    printf "\n  TRACK %02d AUDIO\n" "$track_num" >> "$cue_file"
    start_found=false
  fi

  # ISRC ###
  if [[ "$toc_line" =~ ISRC\ \"(.*)\" ]] && [[ "$track_num" -gt '0' ]]; then
    echo "    ISRC \"${BASH_REMATCH[1]}\"" >> "$cue_file"
  fi

  # TITLE ###
  if [[ "$toc_line" =~ TITLE\ \"(.*)\" ]]; then
    title_info=$(printf "%b" "${BASH_REMATCH[1]}")
    if [[ "$track_num" -gt '0' ]]; then
      echo "    TITLE \"${title_info}\"" >> "$cue_file"
    else
      echo "TITLE \"${title_info}\"" >> "$cue_file"
    fi
  fi

  # PERFORMER configuration globale ou par piste audio ###
  if [[ "$toc_line" =~ PERFORMER\ \"(.*)\" ]]; then
    performer_info=$(printf "%b" "${BASH_REMATCH[1]}")
    if [[ "$track_num" -gt '0' ]]; then
      echo "    PERFORMER \"${performer_info}\"" >> "$cue_file"
    else
      echo "PERFORMER \"${performer_info}\"" >> "$cue_file"
    fi
  fi

  # INDEX ###
  if [[ "$toc_line" =~ FILE\ \".*\"\ (0|[0-9]+:[0-9]+:[0-9]+)\ ([0-9]+:[0-9]+:[0-9]+) ]]; then
    if [[ "${BASH_REMATCH[1]}" == '0' ]]; then
      begin_audio_track='00:00:00'
    else
      begin_audio_track="${BASH_REMATCH[1]}"
    fi
  fi

  # START ###
  # Calcul des INDEX avec ligne START
  if [[ "$toc_line" =~ START\ ([0-9]+:[0-9]+:[0-9]+) ]]; then
    track_transition="${BASH_REMATCH[1]}"
    calculindex "$begin_audio_track" "$track_transition" >> "$cue_file"
    start_found=true
    begin_audio_track=''
    track_transition=''
  fi
done < "$toc_file"

# Ajouter la valeur d'INDEX 01 pour la dernière piste si START est manquant
if [[ "$start_found" == false ]]; then
  calculindex "$begin_audio_track" "$track_transition" | grep 'INDEX 01' >> "$cue_file"
fi

echo "Conversion du fichier $toc_file vers $cue_file terminée !"
