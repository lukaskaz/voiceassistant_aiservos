#!/bin/bash

SCRIPTDIR=$(dirname $(readlink -f $0))
CONFIGFILE=$SCRIPTDIR/config.data
. $SCRIPTDIR/cam_servos_control.sh

declare -A LANGSET=( \
[pl,id]="pl" \
[pl,code]="pl-pl" \
[en,id]="en" \
[en,code]="en-us" \
)

declare -A QUERYSET=( \
[pl,txt1]="Czego ci potrzeba?" \
[en,txt1]="What do you need"? \
)

declare -A BEGINSET=( \
[pl,txt1]="Rozpoczynam nasłuch" \
[en,txt1]="Starting to listen" \
[handler]=_initcb \
)

declare -A GETTIMESET=( \
[pl,txt1]="Jest teraz godzina" \
[en,txt1]="Now it's" \
[pl,key]="która.*godzina\|podaj.*godzinę\|jaka.*godzina" \
[param]=_gettime \
)

declare -A GETDATESET=( \
[pl,txt1]="Mamy dziś" \
[en,txt1]="Today is" \
[pl,key]="data\|datę\|jaki.*dzień" \
[param]=_getdate \
)

declare -A GETNAMESET=( \
[pl,txt1]="Mam na imię" \
[en,txt1]="My name is" \
[pl,key]="twoje.*imię\|masz.*imię" \
[param]=_getname \
)

declare -A SINGSTHSET=( \
[pl,txt1]="Jasne zaśpiewam, hahaha" \
[en,txt1]="Sure I'll sing, ha haha" \
[pl,txt2]="Przez twe oczy, te ooooczy zielone o o o o ooooooooszalałeem" \
[en,txt2]="Because of your eyesssssssss, your greeeeeeeeeen eyesssss, I've gone ma ma ma maaaaaaaaaad" \
[pl,txt3]="Koniec. I jak?" \
[en,txt3]="And that's it. How was it?" \
[pl,key]="możesz zaśpiewać\|zaśpiewaj" \
)

declare -A SINGOKSET=( \
[pl,txt1]="Jasne zaśpiewam, hahaha" \
[en,txt1]="Sure I'll sing, ha haha" \
)

declare -A TRANSLATESET=( \
[pl,txt1]="Po niemiecku to" \
[en,txt1]="In german that is" \
[pl,key]="przetłumacz" \
[param]=_gettranslate \
[handler]=_translatecb \
)

declare -A SETVOLUMESET=( \
[pl,txt1]="Ustawiam głośność na" \
[en,txt1]="Set volume to" \
[pl,key]="ustaw głośność na" \
[param]=_getvol \
[handler]=_setmainvolcb \
)

declare -A INCRVOLUMESET=( \
[pl,txt1]="Ustawiam głośność na" \
[en,txt1]="Set volume to" \
[pl,key]="podgłośnij o" \
[param]=_getvol \
[handler]=_incrmainvolcb \
)

declare -A DECRVOLUMESET=( \
[pl,txt1]="Ustawiam głośność na" \
[en,txt1]="Set volume to" \
[pl,key]="ścisz o" \
[param]=_getvol \
[handler]=_decrmainvolcb \
)

declare -A STREAMYTSET=( \
[pl,txt1]="Odtwarzam Frediego Mercurego" \
[en,txt1]="Playing Freddy Mercury" \
[pl,key]="odtwórz.*youtub" \
[handler_after]=_streamytcb \
)

declare -A STREAMRADIOSET=( \
[pl,txt1]="Streamuję radio RMF FM" \
[en,txt1]="Streaming radio RMF FM" \
[pl,key]="włącz.*radio" \
[handler_after]=_streamradiocb \
)

declare -A STREAMKILLSET=( \
[pl,txt1]="Streaming zakończony" \
[en,txt1]="Streaming closed" \
[pl,key]="zabij.*stream" \
[handler]=_streamendcb \
)

declare -A STREAMVOLSET=( \
[handler]=_streamvolcb \
)
declare -A INITSERVOSSET=( \
[pl,txt1]="Inicuje sprzęganie serw" \
[en,txt1]="Commencing engage of servos" \
[pl,key]="aktywuj.*serwa" \
[handler_after]=_initservoscb \
)

declare -A SETLOWSERVOSET=( \
[pl,txt1]="Ustawiłem dolne serwo w pozycji" \
[en,txt1]="Low servo aligned to" \
[pl,key]="ustaw.*dolne.*serwo" \
[param]=_getservopos \
[handler]=_setlowservocb \
)

declare -A CHGLANGTOENG=(\
[pl,txt1]="Zmieniam na język angielski" \
[pl,txt2]="przejmuje koleżanka" \
[pl,key]="zmień.*angielski" \
[handler_after]=_chglangtoengcb \
)

declare -A CHGLANGTOPL=(\
[en,txt1]="Changing to polish language" \
[en,txt2]="my colleague is taking over" \
[pl,key]="zmień.*polski" \
[handler_after]=_chglangtoplcb \
)

declare -A EXITAPPSET=( \
[pl,txt1]="Zamykam nasłuch"
[pl,txt2]="Na razie" \
[en,txt1]="Closing VR" \
[en,txt2]="See ya" \
[pl,key]="zakończ\|zamknij" \
[handler]=_exitappprepare
[handler_after]=_exitapp
)

declare -A UNKNOWNSET=( \
[pl,txt1]="Z tym nie pomogę" \
[en,txt1]="I cannot help with that" \
[pl,key]=".*" \
)

declare -a APPCMDS=( GETTIMESET GETDATESET GETNAMESET SINGSTHSET TRANSLATESET SETVOLUMESET INCRVOLUMESET DECRVOLUMESET STREAMYTSET STREAMRADIOSET STREAMKILLSET CHGLANGTOPL CHGLANGTOENG INITSERVOSSET SETLOWSERVOSET EXITAPPSET UNKNOWNSET )

STREAMFIFO=mplayervol.fifo

function _initcb
{
	local CONFIG=$(cat $CONFIGFILE | egrep -v "^#.*")

	rm -f $STREAMFIFO
	STTKEY=$(echo "$CONFIG" | grep googleapikey | sed -r "s/^googleapikey:(.*)/\1/g")
	STTURI=$(echo "$CONFIG" | grep googlestturi | sed -r "s/^googlestturi:(.*)/\1/g")
	TTSURI=$(echo "$CONFIG" | grep googlettsuri | sed -r "s/^googlettsuri:(.*)/\1/g")
	STTRATE=$(echo "$CONFIG" | grep sttsamplerate | sed -r "s/^sttsamplerate:(.*)/\1/g")
	STTFILE=$(echo "$CONFIG" | grep sttfile | sed -r "s/^sttfile:(.*)/\1/g")
	STTHEADER=$(echo "$CONFIG" | grep googlesttheader | sed -r "s/^googlesttheader:(.*)/\1/g")$STTRATE
	STTCONFIDPERC=$(echo "$CONFIG" | grep sttconfidperc | sed -r "s/^sttconfidperc:(.*)/\1/g")
	TTSFILE=$(echo "$CONFIG" | grep ttsfile | sed -r "s/^ttsfile:(.*)/\1/g")
	APPLANG=$(echo "$CONFIG" | grep applang | sed -r "s/^applang:(.*)/\1/g" | tr '[:upper:]' '[:lower:]')

	APPLANGID=${LANGSET[$APPLANG,id]}
	APPLANGCODE=${LANGSET[$APPLANG,code]}

	echo "Initialization is over, starting to listen..."
}

function _gettime
{
	echo `eval date +"%H:%M"`
}

function _getdate
{
	echo `eval date +"%d/%m/%Y"`
}

function _getname
{
	echo `eval hostname`
}

function _getvol
{
	echo $VOLUMETOSET
}

function _setmainvolcb
{
	VOLVAL=$(echo "$1" | sed -r "s/.*([Uu]staw głośność na )+([0-9]+){1,3}.*/\2/g")

	if [ -n "$VOLVAL" ]; then
		VOLVAL="$VOLVAL%"
		echo "Setting main volume to $VOLVAL"
		export VOLUMETOSET=$VOLVAL
		amixer set PCM $VOLUMETOSET|tail -1
		#amixer set 'SRS-XB22 - A2DP' $MOD|tail -1
	fi
}

function _incrmainvolcb
{
	VOLVAL=$(echo "$1" | sed -r "s/.*(podgłośnij o )+([0-9]+){1,3}.*/\2/g")

	if [ -n "$VOLVAL" ]; then
		CURRENT=$(amixer get PCM|tail -1|sed -r "s/.*\[([0-9]+)([%]{1})\].*/\1/g")
		let VOLVAL="$VOLVAL + $CURRENT"
		if [ $VOLVAL -gt 100 ]; then VOLVAL=100; fi

		VOLVAL="$VOLVAL%"
		echo "Setting main volume to $VOLVAL"
		export VOLUMETOSET="$VOLVAL"
		amixer set PCM $VOLUMETOSET|tail -1
		#amixer set 'SRS-XB22 - A2DP' $MOD|tail -1
	fi
}

function _decrmainvolcb
{
	VOLVAL=$(echo "$1" | sed -r "s/.*(ścisz o )+([0-9]+){1,3}.*/\2/g")

	if [ -n "$VOLVAL" ]; then
		CURRENT=$(amixer get PCM|tail -1|sed -r "s/.*\[([0-9]+)([%]{1})\].*/\1/g")
		let VOLVAL="$CURRENT - $VOLVAL"
		if [ $VOLVAL -lt 0 ]; then VOLVAL=0; fi

		VOLVAL="$VOLVAL%"
		echo "Setting main volume to $VOLVAL"
		export VOLUMETOSET="$VOLVAL"
		amixer set PCM $VOLUMETOSET|tail -1
		#amixer set 'SRS-XB22 - A2DP' $MOD|tail -1
	fi
}

function _streamradiocb
{
	rm -f $STREAMFIFO &> /dev/null
	mkfifo $STREAMFIFO
	(mplayer -novideo -softvol -input file=$STREAMFIFO -playlist  http://www.rmfon.pl/n/rmffm.pls &>/dev/null && rm -f $STREAMFIFO &)
}


function _streamytcb
{
	echo "Playing YT"

	rm -f $STREAMFIFO &> /dev/null
	mkfifo $STREAMFIFO
	(mplayer -novideo -softvol -input file=$STREAMFIFO $(youtube-dl -q -f 18 -g https://youtu.be/DedaEVIbTkY) &>/dev/null && rm -f $STREAMFIFO) &
}

function _streamendcb
{
	killall mplayer
	rm -f $STREAMFIFO
}

function _streamvolcb
{
	VOLCMD=$1

	if [ -e "$STREAMFIFO" ]; then
		if [ "$VOLCMD" == "FULL" ]; then
			echo "Full stream volume"
			echo "volume 100 1" > $STREAMFIFO
		elif [ "$VOLCMD" == "QUIET" ]; then
			echo "Quiet stream volume"
			echo "volume 5 1" > $STREAMFIFO
		fi
	fi
}

function _gettranslate
{
	echo $TRANSLATEDPHRASE
}

function _translatecb
{
	local PHRASE=$(echo $1|sed -r "s/.*[Pp]rzetłumacz (.*)/\1/g")	

	if [ -n "$PHRASE" ]; then
		local WORDS=$(echo $PHRASE | wc -w)
		echo "Translating $PHRASE to German"
		
		if [ $WORDS -eq 1 ]; then
			PHRASE="the $PHRASE"
		fi

		echo "Pharse: $PHRASE"
		RESULT=$(wget -U "Mozilla/5.0" -qO - "http://translate.googleapis.com/translate_a/single?client=gtx&sl=pl&tl=de&dt=t&q=$PHRASE"|head -1|sed -r "s/\[\[\[\"([^\"]+).*/\1/g")

		echo "RESULT: $RESULT" 
		export TRANSLATEDPHRASE=$RESULT
	fi
}

function _initservoscb
{
	_init_servos
}

function _getservopos
{
	echo $SERVOPOSTOSET
}

function _setlowservocb
{
	echo $1 | grep -i minus &> /dev/null
	SIGN=$?
	POSVAL=$(echo "$1" | sed -r "s/.*(serwo na )+(minus )*([0-9]+){1,3}.*/\3/g")
	if [ -n "$POSVAL" ]; then
		if [ $SIGN -eq 0 ]; then POSVAL="-$POSVAL"; fi
		export SERVOPOSTOSET="$POSVAL stopni"
		_set_low_servo_pos $POSVAL
	fi
}

function _chglangtoengcb
{
	APPLANG="en"
	APPLANGID=${LANGSET[$APPLANG,id]}
	APPLANGCODE=${LANGSET[$APPLANG,code]}
}

function _chglangtoplcb
{
	APPLANG="pl"
	APPLANGID=${LANGSET[$APPLANG,id]}
	APPLANGCODE=${LANGSET[$APPLANG,code]}
}

function _exitappprepare
{
	_streamendcb
}

function _exitapp
{
	exit 0
}

