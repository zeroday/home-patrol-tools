find . -size +20k -iname *.wav -type f -exec ffmpeg -i {} -codec:a libmp3lame -qscale:a 2 {}.mp3 -y \; -exec /bin/rm {} \;