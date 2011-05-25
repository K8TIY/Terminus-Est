#!/bin/bash

mkdir foma
svn co http://foma.svn.sourceforge.net/svnroot/foma/trunk/foma
cd foma
make
rm *.o
echo "Tried to run make..."
echo "but you may have to download and install flex 2.5.35 if you got errors."
echo "Good luck!"
