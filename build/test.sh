#!/bin/sh

#
# Handier way to build and test and see coverage
# By Leandro Motta Barros
#

# Clean everything
./clean.sh

# Build and run unit tests
premake5 gmake \
    && make -j8 config=test UnitTests \
    && ./UnitTests

if [ $? != 0 ]; then
    exit
fi

# Print a nice coverage report
shallThisFileBeIgnored()
{
    # Ignore test data for noise
    if [ "$1" == "..-src-sbxs-noise-test_data-open_simplex_noise_data.lst" ]; then
        return 0
    else
        return 1
    fi
}


report=""
for f in .*.lst; do
    shallThisFileBeIgnored "$f"
    if [ $? == 0 ]; then
        continue
    fi
    line=`tail -n 1 $f`
    fileName=`echo $line | cut -d' ' -f 1`
    coverage=`echo $line | cut -d' ' -f 3`
    report="$coverage $fileName\n$report"
done

echo -e $report | sort -n -r
