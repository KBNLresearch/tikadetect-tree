#!/bin/bash

# Identify format of each file in directory tree with Apache Tika, using the Tika server,
# and with Unix File.
# Works also for file and directory names that contain spaces.
#
# Dependencies:
#
# - java
# - tika-server 
# - curl
#
# **************
# CONFIGURATION
# **************

# Location of Tika server Jar
tikaServerJar=~/tika/tika-server-1.16.jar

# Server URL
tikaServerURL=http://localhost:9998/

# Defines no. of seconds script waits to allow the Tika server to initialise   
sleepValue=3

# **************
# I/O
# **************

# Check command line args
if [ "$#" -ne 2 ] ; then
  echo "Usage: testdetect-tree.sh rootDirectory outputFile" >&2
  exit 1
fi

if ! [ -d "$1" ] ; then
  echo "rootDirectory must be a directory" >&2
  exit 1
fi

# Root directory
rootDir="$1"

# Output file
outFile="$2"

# File to store stderr output for tika server and detect process
tikaServerErr=tika-server.stderr
tikaDetectErr=tika-detect.stderr

# File to store stderr output for Unix File
fileErr=file.stderr

# Delete output file if it exists already
if [ -f $outFile ] ; then
  rm $outFile
fi

# Delete tika server stderr file if it exists already
if [ -f $tikaServerErr ] ; then
  rm $tikaServerErr
fi

# Delete tika detect stderr file if it exists already
if [ -f $tikaDetectErr ] ; then
  rm $tikaDetectErr
fi

# Delete File stderr file if it exists already
if [ -f $fileErr ] ; then
  rm $fileErr
fi

# **************
# LAUNCH TIKA SERVER
# **************

# Launch the Tika server as a subprocess
java -jar $tikaServerJar 2>>$tikaServerErr & export Tika_PID=$!

echo "Waiting for Tika server to initialise ..."
sleep $sleepValue

# **************
# PROCESS DIRECTORY TREE
# **************

echo "Processing directory tree ..."

# Write header fields to output file 
echo fileName,mimeTypeTika,mimeTypeFile,matchTika,matchFile,mimeTypesIdentical > $outFile

# Record start time
start=`date +%s`

# This works for filenames that contain whitespace using code adapted from:
# http://stackoverflow.com/questions/7039130/bash-iterate-over-list-of-files-with-spaces/7039579#7039579

while IFS= read -d $'\0' -r file ; do
    # File basename (used as filename hint by Tika in -H option)
    # In production workflow bName could be read from metadata, in case actual file doesn't have original name/extension 
    bName=$(basename "$file")
    # Submit file to Tika server
    mimeTypeTika=$(curl -H "Content-Disposition: attachment; filename=$bName" -X PUT --upload-file "$file" "$tikaServerURL"detect/stream 2>> $tikaDetectErr)
    mimeTypeFile=$(file --mime-type "$file" | cut -d':' -f2 | cut -d' ' -f2 2>> $fileErr)

    if [ "$mimeTypeTika" == "application/octet-stream" ]
    then
        matchTika=0
    else
        matchTika=1
    fi
    
    if [ "$mimeTypeFile" == "application/octet-stream" ]
    then
        matchFile=0
    else
        matchFile=1
    fi

    if [ "$mimeTypeTika" == "$mimeTypeFile" ]
    then
        mimeTypesIdentical=1
    else
        mimeTypesIdentical=0
    fi
    
    echo $file,$mimeTypeTika,$mimeTypeFile,$matchTika,$matchFile,$mimeTypesIdentical >> $outFile
done < <(find $rootDir -type f -print0)
 
# Record end time
end=`date +%s`

runtime=$((end-start))

echo "Running time for processing directory tree:" $runtime "seconds"

# Kill Tika server process
kill $Tika_PID

