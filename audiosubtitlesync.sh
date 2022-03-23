#Concatenates a set of MP3 files to match the timestamps of the subtitle from which they were created
#by inserting silences at the end where needed. It cannot do miracles though if there is not enough
#time, so definitely check the output, ideally with someone who speaks the language of the subtitle file 
#Produces two files, one with leading silence (up to the start of the first subtitle), one without ("trimmed")
#The MP3 files must be named in the correct numerical/chronological order (and remove spaces from all file names)
#Expects to be run in a folder that contains all MP3 files for a .srt file which is also located in the same folder. 
#No other MP3 files in the folder (for instance from previous runs of the same script)
#Expects ffmpeg and sox to be installed on the system
#
timestamp() {
    date '+%s.%3N' --date="$1"
}
video=$(basename "$1" .srt)
videostart=$(timestamp "00:00:00,000")
firstsubtitle=$(timestamp `grep -m1 '\-->' $video.srt |tail -1|cut -d' ' -f1`)
lag=0
for file in *.mp3
do
  let n++  
  echo -n "$n $file	"
  subtitlestart=$(timestamp `grep -m$n '\-->' $video.srt |tail -1|cut -d' ' -f1`)
  subtitleend=$(timestamp `grep -m$n '\-->' $video.srt |tail -1|cut -d' ' -f3`)
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
sox pad_*.mp3 "$video"_trimmed.mp3
rm pad_*.mp3
echo "Adding initial padding..."
start=$(timestamp "00:00:00,000")
initialpadding=$( echo "scale=3;$firstsubtitle - $videostart"|bc )
sox "$video"_trimmed.mp3 $video.mp3 pad $initialpadding 0
echo "$video.mp3 is ready"
