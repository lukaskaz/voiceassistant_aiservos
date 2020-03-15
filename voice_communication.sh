#!/bin/bash

SCRIPTDIR=$(dirname $(readlink -f $0))
. $SCRIPTDIR/common_data.sh


function _extract_from_stt
{
	local RET=1
	local FILE=$1
	local RESP=""
	local RESULT=$2
	local GETSTTFN="wget -q -U 'Mozilla/5.0' --post-file $FILE --header $STTHEADER -O - $STTURI&lang=pl&key=$STTKEY"
	
	RESP=$($GETSTTFN)
	echo $RESP | grep -i "transcript" &> /dev/null
	if [ $? -eq 0 ]; then 
		CONFID=$(echo $RESP|sed -r "s/^.*\{\"transcript\":\"([^\"]+).*confidence\":([^\}]+).*/\2/g")
		CONFID=$(echo "$CONFID * 100 / 1" | bc)
		echo "I am sure in [$CONFID%] for threshold [$STTCONFIDPERC%]"
		if [ $CONFID -ge $STTCONFIDPERC ]; then
			RESP=$(echo $RESP|sed -r "s/^.*\{\"transcript\":\"([^\"]+).*confidence\":([^\}]+).*/\1/g")
			echo -e "$RESP \c" >> $RESULT
			echo "I have got stt '$RESP'"
			RET=0
		else
			RESULT=""
		fi
	fi

	return $RET
}

function _get_from_voice
{
	local -n RESULT=$1
	local RET=1
	local STTRESP=""
	local FILENO=1
	local FILENEXTNO=2
	local RESPDATA="/dev/shm/respdata.file"
	local STTDIR="stt"
	local STTTMPDIR="totraslate"
	local STTFILE="$STTDIR/$STTFILE"
	local STTTRIGGERWORD="słuchaj robot"
	local SNDRECTRIGCMD="sox -q -r 16000 -c 1 -t alsa default $STTFILE silence -l 1 1 2% 1 0.5 1% pad 0.2 0.5"
	local SNDRECCMD="sox -q -r 16000 -c 1 -t alsa default $STTFILE silence -l 1 1 2% 1 0.3 1% pad 0.2 0.5"

	if [ -d $STTDIR ]; then
		rm -rf $STTDIR/*
		mkdir $STTDIR/$STTTMPDIR
	else
		mkdir -p $STTDIR/$STTTMPDIR
	fi

	while true; do
		echo -e '\c' > $RESPDATA
		$SNDRECTRIGCMD 2> /dev/null
		echo "SOUND..."
		_extract_from_stt $STTFILE $RESPDATA
		cat $RESPDATA | grep -i "$STTTRIGGERWORD" &> /dev/null
		if [ $? -eq 0 ]; then
			_say_by_voice QUERYSET  
			rm $STTFILE
			break
		fi
	done
	
	$SNDRECCMD : newfile : restart 2>/dev/null &
	
	echo -e '\c' > $RESPDATA
	cd $STTDIR &> /dev/null
	echo "Speak NOW..."
	FILE=$(inotifywait -e create . | sed -r "s/.* CREATE (.*)/\1/g")

	inotifywait -e close_write $FILE &> /dev/null
	while true; do
		ALLFILES=$(ls -p | grep -v /)
		FILESNB=$(echo $ALLFILES | wc -w)
		if [ $FILESNB -eq 0 ]; then
			inotifywait -e create . &> /dev/null
		else
			FILE=$(echo "$ALLFILES" | head -1)
			if [ $FILESNB -eq 1 ]; then
				inotifywait -q -t 1 -e modify $FILE &> /dev/null
				if [ $? -ne 0 ]; then
					break
				else
					while fuser $FILE &> /dev/null; [ $? -eq 0 ]; do sleep 0.1; done
				fi
			fi

			mv $FILE $STTTMPDIR/
			_extract_from_stt $STTTMPDIR/$FILE $RESPDATA &
		fi
	done
	cd - &> /dev/null

	killall sox
	RESULT=$(cat $RESPDATA)
	echo "${FUNCNAME[0]} completed with retcode $RET : RESULT $RESULT"
	return $RET
}

function _say_by_voice
{
	local RET=0
	if [ -z "$2" ]; then
		declare -n CMDARR=$1
		local LANGTOUSE=$APPLANGCODE
	else
		local -n CMDARR=$2
		local LANGTOUSE=$1
	fi

	for i in $(seq 50); do
		local TEXTTOSAY=${CMDARR[$APPLANGID,txt$i]}

		if [ -n "$TEXTTOSAY" ]; then
			if [ -n "${CMDARR[param]}" ]; then
				local TEXTPARAM=$(${CMDARR[param]})
			fi

			if [ -n "$TEXTPARAM" ]; then
				TEXTTOSAY="$TEXTTOSAY $TEXTPARAM"
			fi

			${STREAMVOLSET[handler]} QUIET	
			wget -q -U Mozilla -O $TTSFILE "$TTSURI&q=$TEXTTOSAY&tl=$LANGTOUSE" &> /dev/null
			if [ $? -eq 0 ]; then
				play $TTSFILE &> /dev/null
			fi
		else
			break
		fi
	done

	RET=$?
	echo "${FUNCNAME[0]} completed with retcode $RET"
	return $RET
}

function _cleanup
{
	echo "Cleaning on exit"
	rm -f $STREAMFIFO $STTFILE $TTSFILE
	echo "Exitting due to retcode $1"
}

function _initialize
{
	declare -n cmdset=$1

	${cmdset[handler]}
	_say_by_voice cmdset
}

trap "_cleanup $?" EXIT

##### main #####
RESP=""

_initialize BEGINSET
while true; do
	${STREAMVOLSET[handler]} FULL
	_get_from_voice RESP

	for cmd in "${APPCMDS[@]}"; do
		declare -n cmdset=$cmd
		cmdkey=${cmdset[pl,key]}
		if [ -n "$cmdkey" ]; then
			echo $RESP | grep -i "$cmdkey"
			if [ $? -eq 0 ]; then
				${cmdset[handler]} "$RESP"
				_say_by_voice $cmd
				${cmdset[handler_after]} "$RESP"
				break
			fi
		fi
	done
done

exit 0
##### end ######
