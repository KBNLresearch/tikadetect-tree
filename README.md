## Tikadetect-tree

This is a simple bash script that performs file format identification on all files in a directory tree using Apache Tika. Results are reported as a comma-delimited text file. The script first launches Tika's [network server](https://wiki.apache.org/tika/TikaJAXRS) as a background process, and subsequently submits all files in a user-defined directory tree to the detector interface. Afterwards the server process is killed.

## Installation

First you need to download the Tika Server runnable JAR (*tika-server-x.xx.jar*), which can be found here:

<https://tika.apache.org/download.html> 

After downloading, just put it in any directory you like.

Next update the value of *tikaServerJar* to the path of the JAR on your system. For example:

    tikaServerJar=~/tika/tika-server-1.16.jar
    
You may need to make the script executable using:

    chmod 755 tikadetect-tree.sh

## Running the script

Basic usage is:

    tikadetect-tree.sh rootDirectory outputFile

Here *outputFile* is a comma-delimited file. Each line consists of the full path to a file, followed by its corresponding mimetype string.

