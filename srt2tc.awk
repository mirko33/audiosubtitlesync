# awk -f <this_script> <some_srt_file>
# Creates two files named by appending ".content" and ."timing" to the srt file name
# The .content file only contains the lines with actual subtitle text, which can
# then used for instance to generate speech, and
# the .timing file contains the timestamps from the .srt file, but not without 
# eliminating any gaps between subtitles.
# The .timing file can be used as input for the speech-subtitle alignment script
#
# The input .srt file should be a modified version of the original .srt file that 
# is adapted to the needs of speech generation (joined sentences broken across one or
# more subtitles, different spelling of certain words to ensure they're pronounced right etc.
/-->/ {
	if (!notfirst) {
		printf $1 > FILENAME".timing"
		printf "" > FILENAME".content" 
		notfirst=1
	}
	else {
		printf " --> " $1 "\n" $1 >> FILENAME".timing"
		last=$3
	}
	next
    }
!/^[0-9]*\r/ { print $0 >> FILENAME".content" }
END { print " --> " last >> FILENAME".timing" }
