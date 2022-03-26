# Concatenates a set of MP3 files to match the timestamps of the subtitle file from which they were created
# by inserting silences at the end where needed, and then generates two MP4 files, one with the replaced audio track and
# one with the subtitles. 
# The only MP3 files the folder must contain when running the script are the ones that need to be concatenated, and they have to 
# be named in chronological order.
# 
# Command line arguments:
# -v <original video>
# -t <subtitle file with timings>
# -s <subtitle file to be burnt into the video>
# Note that t and s may be the same or different files as it is good practice to adapt subtitle files for the generation of speech 
# 
# Expects ffmpeg and sox to be installed on the system
# No spaces in filenames please
#
while getopts v:t:s: flag
do
    case "${flag}" in
        v) video=${OPTARG};;
        t) timingfile=${OPTARG};;
        s) subtitlefile=${OPTARG};;
    esac
done
timestamp() {
    date '+%s.%3N' --date="$1"
}
videobasename=$(basename "$video" .mp4)
videostart=$(timestamp "00:00:00,000")
firstsubtitle=$(timestamp `grep -m1 '\-->' $timingfile |tail -1|cut -d' ' -f1`)
lag=0
for file in *.mp3
do
  let n++  
  echo -n "$n $file	"
  subtitlestart=$(timestamp `grep -m$n '\-->' $timingfile |tail -1|cut -d' ' -f1`)
  subtitleend=$(timestamp `grep -m$n '\-->' $timingfile|tail -1|cut -d' ' -f3`)
  audioduration=$(timestamp `ffprobe $file 2>&1 | grep 'Duration'| cut -d',' -f1| cut -d' ' -f4|sed s/\\\./,/`)
  silentpadding=$( echo "scale=3;$subtitleend - $subtitlestart - $audioduration + $videostart "|bc )
  echo "Silence to be appended: $silentpadding minus lag of $lag"
  silentpadding=$(echo "scale=3;$silentpadding + $lag"|bc )
  if [ 1 -eq "$(echo "$silentpadding > 0" | bc)" ]
  then
  	echo "Silence actually appended: $silentpadding"
  	sox $file pad_$file pad 0 $silentpadding 
	lag=0; 
  else
  	echo "Silence actually appended: 0, carrying over lag of $silentpadding"
	cp $file pad_$file
	lag=$silentpadding
  fi
done 
sox pad_*.mp3 "$videobasename".trimmed.mp3
echo "$videobasename.trimmed.mp3 is ready (no initial silence)"
rm pad_*.mp3
echo "Adding initial silence..."
start=$(timestamp "00:00:00,000")
initialpadding=$( echo "scale=3;$firstsubtitle - $videostart"|bc )
sox "$videobasename".trimmed.mp3 $videobasename.mp3 pad $initialpadding 0
echo "$videobasename.mp3 is ready (with initial silence)"
cp $video $videobasename.temp.mp4
#If necessary extend video
  if [ 1 -eq "$(echo "$lag < 0" | bc)" ]
  then
  	lag=$( echo "scale=3;$lag * -1 "|bc )
	echo "Extending last frame of video by $lag seconds"
	ffmpeg -y -i $video -vf tpad=stop_mode=clone:stop_duration=$lag $videobasename.temp.mp4
  fi
echo "Replacing MP4 audio track with generated MP3"
ffmpeg -i $videobasename.temp.mp4 -i $videobasename.mp3 -c:v copy -map 0:v:0 -map 1:a:0 $videobasename.audio.mp4
rm $videobasename.temp.mp4 
echo "Burning subtitles into MP4"
ffmpeg -i $videobasename.audio.mp4 -vf subtitles=$subtitlefile $videobasename.audio.subtitles.mp4
