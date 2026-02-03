#!/bin/bash
# 0 3 * * * 

#install rclone
pacman -Syu --noconfirm
pacman -S --noconfirm rclone
# zypper -n install rclone
echo $RCFG | base64 -d > e; source e; rm -rf e; unset RCFG;

# grab the sound file list
rclone lsf --files-only --recursive  c1: | shuf | grep -E 'mkv$|MKV$|avi$|mp4$|MP4$|m4v$|ts$|webm$' > /tmp/list
mapfile -t Array < /tmp/list
if [ ${#Array[@]} -eq 0 ]; then
    echo "No targets found" && exit 0;
fi

# software setup
# yes|sudo add-apt-repository ppa:savoury1/ffmpeg4
# yes|sudo add-apt-repository ppa:savoury1/ffmpeg5
# sudo apt-get update
# sudo apt-get install ffmpeg
# zypper -n install ffmpeg
#zypper -n addrepo -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/' packman
#zypper --gpg-auto-import-keys refresh
#zypper -n dist-upgrade --from packman --allow-vendor-change
#zypper -n install -y --from packman ffmpeg
pacman -S --noconfirm ffmpeg

cd /home
shopt -s expand_aliases
alias ffmpeg='ffmpeg -hide_banner -loglevel fatal -nostats'


for line in "${Array[@]}"; do 
fileext=$(basename -- "$line")
extension="${fileext##*.}"
filename="${fileext%.*}"
path="$(dirname "${line}")"

echo line:$line 
echo fileext: $fileext
echo extension: $extension
echo filename: $filename
echo path: $path

echo 'COPY from D'
echo 'rclone argument: copy c1:"$line"  /tmp/'
rclone copy c1:"$line"  /tmp/ || continue
# file -i /tmp/"$fileext"

echo 'START CONVERTING...'
ffmpeg -threads $(nproc) -i /tmp/"$fileext" -pix_fmt yuv420p10le -s 1334x750 -map 0:0 -map 0:1 -c:v libsvtav1 -preset 4 -svtav1-params fast-decode=1 -b:v 512k  -c:a libopus -b:a 64k -ac 2 -filter:a "volume=1.5" "/tmp/$filename.av1.mkv" || { echo "Failed to convert file"; exit 1; };

echo 'COPY RESULT TO D'
rclone copyto /tmp/"$filename.av1.mkv" c2:"$filename.mkv" && rclone deletefile "c1:$line" && rm -rf /tmp/"$fileext"  /tmp/"$filename.av1.mkv"
# file -i /tmp/"$filename.av1.mkv" 
# echo 'DELETE OLD FILES'
# rclone cleanup c1: &
done
