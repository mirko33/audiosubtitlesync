# audiosubtitlesync
Bash script to generate MP4 with audio track that is synchronised with the subtitles from which it was generated 

Also includes a little awk script that supports the creation of a content-only version of the .srt file, and the corresponding timings, in two separate files. The timings are fixed to avoid unnecessary breaks between the subtitles. 

The overall process of the subtitle and speech generation video localisation process looks like this:

1. An editor/translator creates a modified version of the original .srt file (the audio script) that is better suited for speech generation. Among the modifications are the joining of sentences broken across two or more segments and the editing of abbrevations, acronyms and other problematic words to ensure their correct pronunciation. (The joining of segments logically involves the removal of timestamps which in turn would lead to unwanted gaps between subtitles; this is what the awk script fixes.)
1. An engineer runs the awk script on the audio script
1. The engineer uses the .content file to generate the speech files
1. The engineer downloads the speech files and runs the bashscript
1. The editor/translator checks the resulting video for poor pronunciation and misalignments between speech and subtitles. Fixing the pronunciation will require restarting from step 1. Fixing alignment will most likely require going back to 3. to regenerate the audio with a higher rate (speed). If however no issues are found, the engineer can deliver the different files produced: 
   - MP4 with and without subtitles
   - Concatenated MP3 files (with and without leading silence)
   - The audioscript 
