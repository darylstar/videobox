#!/bin/bash
# 0 3 * * * 

curl https://rclone.org/install.sh | sudo bash 2>&1 1>/dev/null
mkdir -p ~/.config/rclone && printf $RCFG > ~/.config/rclone/rclone.conf

# grab the sound file list
rclone lsf --files-only --recursive  d:raw | grep -E 'mkv$|MKV$|avi$|mp4$|MP4$|m4v$' > /tmp/list
mapfile -t Array < /tmp/list
if [ ${#Array[@]} -eq 0 ]; then
    echo "No targets found" && exit 0;
fi
]
# software setup
# yes|sudo add-apt-repository ppa:savoury1/ffmpeg4
# yes|sudo add-apt-repository ppa:savoury1/ffmpeg5
sudo apt-get update
sudo apt-get install ffmpeg

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

echo 'COPY SOUND from D'
echo 'rclone argument: copy gd:abooks/"$line"  /tmp/'
rclone copy d:raw/"$line"  /tmp/ || continue
# file -i /tmp/"$fileext"
echo 'START CONVERING TO Opus'
ffmpeg -threads $(nproc) -i "$fileext" -s 1334x750 -map 0:0 -map 0:1 -c:v libx265 -b:v 450k -preset fast -c:a libopus -b:a 64k -ac 2 -filter:a "volume=1.5" "/tmp/$filename.x265.mkv" || { echo "Failed to convert file"; exit 1; };
echo 'COPY RESULT TO D'
( rclone copy /tmp/"$filename.x265.mkv" d:out/"$path"/ && rclone deletefile "d:raw/$line" && rm -rf /tmp/"$fileext"  /tmp/"$filename.x265.mkv" ) & 
echo 'DELETE OLD FILES'
rclone cleanup d: &
done
echo "ZZzzzzz" && sleep 600
