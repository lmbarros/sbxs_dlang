#!/bin/sh

#
# Handier way to build and test and see coverage
# By Leandro Motta Barros
#

# Remember where we were
initialDirectory=`pwd`

# Build and run unit tests
premake5 gmake \
    && cd build \
    && make \
    && ./UnitTests

if [ $? != 0 ]; then
    exit
fi

# Print a nice coverage report
report=""
for f in .*.lst; do
    if [ $f == "..-src-sbxs-noise-test_data-open_simplex_noise_data.lst" ]; then
        continue
    fi
    line=`tail -n 1 $f`
    fileName=`echo $line | cut -d' ' -f 1`
    coverage=`echo $line | cut -d' ' -f 3`
    report="$coverage $fileName\n$report"
done

echo -e $report | sort -n -r

# Get back to where you once belonged
cd $initialDirectory
