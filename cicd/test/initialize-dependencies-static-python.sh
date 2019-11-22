#!/bin/bash

# ( printf '\n'; printf '%.0s-' {1..30}; printf ' Initialize Python Static Test Dependencies '; printf '%.0s-' {1..30}; printf '\n\n' )

BUILD_LANGUAGE_VERSION=$1

if [ "$BUILD_LANGUAGE_VERSION" == "2" ]; then
	pip install --upgrade pip
	RESULT=$?
	if [ $RESULT -ne 0 ] ; then
		exit 89
	fi
	if [ -f requirements.txt ]; then
	    echo "Using requirements.txt file found in project to install dependencies"
	    pip install -r requirements.txt
		RESULT=$?
		if [ $RESULT -ne 0 ] ; then
			exit 89
		fi
	fi
  pip install pylint nose coverage nosexcover
elif [ "$BUILD_LANGUAGE_VERSION" == "3" ]; then
  pip3 install --upgrade pip
	RESULT=$?
	if [ $RESULT -ne 0 ] ; then
		exit 89
	fi
	if [ -f requirements.txt ]; then
	    echo "Using requirements.txt file found in project to install dependencies"
	    pip3 install -r requirements.txt
		RESULT=$?
		if [ $RESULT -ne 0 ] ; then
			exit 89
		fi
	fi
  pip3 install pylint nose coverage nosexcover
else
	exit 99
fi
