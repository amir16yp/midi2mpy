#!/bin/bash

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

displayinfos=NO
quiet=NO
channel=1
userspeed=1
showbeep=YES
showprogress=YES
midifile=""
langdef="C"
numericdef="en_US.UTF-8"

usage=" $(basename "$0") [-b] [-c=n] [-h] [-i] [-p] [-q] [-s=n] -m=file\n
Program to play a midi track on the PC speaker/buzzer\n
 where:\n
	\t\t-c Choose the MIDI channel you want to play (default : 1)\n
	\t\t-h Display this help\n
	\t\t-i Display infos about the MIDI file (useful for finding channels)\n
	\t\t-m MIDI file to play (mandatory)\n
	\t\t-p Do not display progress info\n
	\t\t-q Doesn't play a sound\n
	\t\t-s Modify the speed of playback (not limited to int)"

for i in "$@"; do
  case $i in
    -s=*|--speed=*)
      userspeed="${i#*=}"
      shift
      ;;
    -m=*|--midi=*)
      midifile="${i#*=}"
      shift
      ;;
    -c=*|--channel=*)
      channel="${i#*=}"
      shift
      ;;
    -q|--quiet)
      quiet=YES
      shift
      ;;
    -b|--hidebeep)
      showbeep=NO
      shift
      ;;
    -p|--noprogress)
      showprogress=NO
      shift
      ;;
    -i|--infos)
      displayinfos=YES
      shift
      ;;
    -h|--help)
      echo -e $usage
      exit
      ;;
    *)
      # unknown option
      ;;
  esac
done

if [[ $midifile == "" ]]; then
  echo -e $usage
  exit
fi

command=""
factor=1
tracks=()

IFS=$'\n'
tab=( $(midi2abc $midifile -midigram) )

IFS=$''
infos=( $(midi2abc $midifile -sum) )

ticks=$(od -An -j 12 -N 2 --endian=big -vd $midifile | xargs)
bpm=$(echo "${infos[@]}" | grep Tempo | awk '{print $2}')
factor=$(echo "60000/($bpm*$ticks)" | bc -l)
factor=$(LANG="${langdef}" LC_NUMERIC="${numericdef}" printf '%.2f' "$factor")

lastend=10000000
lastfirst=10000000

for ((i = 0; i < ${#tab[@]}; i++)); do
  if [[ $showprogress == YES ]]; then
    echo -ne " Done $i notes on ${#tab[@]}      \r"
  fi

  IFS=' '
  arr=( ${tab[$i]} )

  first=${arr[0]}
  track=${arr[3]}

  if [[ $displayinfos == YES ]]; then
    containsElement "$track" "${tracks[@]}"
    if [[ $? -eq 1 ]]; then
      tracks+=(${track})
    fi
  fi

  if [ "$track" = "$channel" ] && [ $lastfirst -ne $first ]; then
    second=${arr[1]}
    midinote=${arr[4]}
    delay=$(bc -l <<< "$userspeed*$factor*($first-$lastend)")
    note=$(bc -l <<< "440*e((($midinote-69)/12)*l(2))")
    note=$(LANG="${langdef}" LC_NUMERIC="${numericdef}" printf '%.2f' "$note")
    time=$(bc -l <<< "$userspeed*$factor*($second-$first)")

    if (( $(bc <<< "$delay > 0") )); then
      echo "SLEEP $(bc <<< "$delay")"
    fi

    echo "BEEP $note $time"
    
    lastend=$second
    lastfirst=$first
  fi
done

if [[ $displayinfos == YES ]]; then
  output="Length ${#tab[@]} ; Ticks $ticks ; BPM $bpm ; Speed factor $factor ; NbChannels ${#tracks[@]} :"

  for ((i = 0; i <= ${#tracks[@]}; i++)); do
    output="$output ${tracks[$i]}"
  done

  echo "$output"
fi

#if [[ $showbeep == YES ]]; then
#  echo "beep $(echo $command | cut -b1-)"
#fi

if [[ $quiet == NO ]]; then
  echo $command | cut -b1- | xargs beep
fi
