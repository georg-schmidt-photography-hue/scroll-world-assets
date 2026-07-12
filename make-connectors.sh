#!/bin/bash
# Synthesische Connector-Flüge (0 Kie-Credits): Push-in auf den letzten Frame von
# Szene N, Crossfade in einen Pull-back auf den ersten Frame von Szene N+1.
# Endpunkte = exakte Nachbar-Frames -> nahtlos an den Dives (SKILL Step 5 Regel).
set -euo pipefail
cd "$(dirname "$0")/../site/assets"

FPS=24; HALF=0.8; XF=0.5   # 2x0.8s Haelften, 0.5s Ueberblendung -> ~1.1s Clip
N=$(python3 -c "print(int($HALF*$FPS))")

for i in 1 2 3 4; do
  j=$((i+1))
  # letzter Frame von leg{i} (exakt: letzter dekodierbarer Frame)
  ffmpeg -y -v error -sseof -0.2 -i "vid/leg${i}.mp4" -update 1 -q:v 1 "/tmp/connA${i}.png"
  # erster Frame von leg{j} = Poster waere jpg-komprimiert; nimm echten Frame 0
  ffmpeg -y -v error -i "vid/leg${j}.mp4" -frames:v 1 -q:v 1 "/tmp/connB${i}.png"

  for tier in "" "-m"; do
    if [ "$tier" = "-m" ]; then CRF=23; G=4; else CRF=20; G=8; fi
    ffmpeg -y -v error \
      -loop 1 -t $HALF -i "/tmp/connA${i}.png" \
      -loop 1 -t $HALF -i "/tmp/connB${i}.png" \
      -filter_complex "\
        [0:v]scale=1280:720,zoompan=z='1+0.45*on/${N}':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=${FPS},format=yuv420p[a];\
        [1:v]scale=1280:720,zoompan=z='1.45-0.45*on/${N}':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=${FPS},format=yuv420p[b];\
        [a][b]xfade=transition=fade:duration=${XF}:offset=$(python3 -c "print($HALF-$XF)")" \
      -an -c:v libx264 -preset slow -crf $CRF -g $G -movflags +faststart \
      "vid/conn${i}${tier}.mp4"
  done
  echo "conn${i} ok"
done
ls -la vid/conn*
