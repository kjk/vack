#!/bin/bash

BUILD_FILE=/tmp/utvackbuild.txt

check_failed() {
    if test $? -ne 0
    then
        echo
        echo "FAILED: $*"
        echo
        if [ -e $BUILD_FILE ]; then
            cat $BUILD_FILE
        fi
        exit 1
    fi
}

echo "cleaning build"
xcodebuild -project VisualAck.xcodeproj clean >$BUILD_FILE
check_failed "build clean"

echo "building"
xcodebuild -project VisualAck.xcodeproj -parallelizeTargets >$BUILD_FILE
check_failed "build"

echo "running tests"
build/Release/utvack ../ack-tests/t
exit 0
