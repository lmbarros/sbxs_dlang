#!/bin/sh

#
# Everyday's handier way to build and test
# By Leandro Motta Barros
#

premake5 gmake \
    && cd build \
    && make \
    && cd .. \
    && build/bin/Test/UnitTests
