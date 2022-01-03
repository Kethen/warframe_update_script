#!/bin/bash
BASE_URL=https://origin.warframe.com
INDEX_FILE=index.txt.lzma
OUTPUT_DIR=warframe
VERBOSE=true

MD5=md5sum
if [ -z "$(command -v md5sum)" ]
then
	# perhaps on bsd?
	if [ -z "$(command -v md5)" ]
	then
		echo either md5 or md5sum is required
		exit 1
	fi
	MD5=md5
fi

MD5SUM () {
	if [ "$MD5" == md5sum ]
	then
		md5sum "$@" | awk '{print $1}'
	else
		md5 -q "$@"
	fi
}

CURL=curl
if [ -z "$(command -v curl)" ]
then
	echo curl is required
	exit 1
fi

LZCAT=lzcat
if [ -z "$(command -v lzcat)" ]
then
	echo lzcat is required
	exit 1
fi

INDEX="$($CURL ${BASE_URL}/${INDEX_FILE} | $LZCAT)"
if [ "$?" != "0" ]
then
	echo failed downloading index file
	exit 1
fi

echo "$INDEX" > index.txt

if ! [ -d "$OUTPUT_DIR" ]
then
	mkdir "$OUTPUT_DIR"
fi

if ! [ -d "$OUTPUT_DIR/Cache.Windows" ]
then
	mkdir "$OUTPUT_DIR/Cache.Windows"
fi

declare -a FILE_LIST
FILE_LIST_INDEX=0

echo comparing files against index
echo file errors begins > file_errors.txt
while read -r LINE
do
	LINE="$(echo $LINE | sed 's/\r//g')"
	FULL_NAME="$(echo $LINE | sed -E 's/\/(.*\/?.*),[0-9]+/\1/')"
	FILE_PATH="$(echo $FULL_NAME | sed -E 's/(.*)\/.*/\1/')"
	FILE_NAME="$(echo $FULL_NAME | sed -E 's/.*\/(.*)/\1/')"
	if [ "$FILE_PATH" == "$FILE_NAME" ]
	then
		FILE_PATH=""
	fi
	CHECKSUM="$(echo $FILE_NAME | sed -E 's/.*\.(.*)\..*$/\1/')"
	POSTFIX="$(echo $FILE_NAME | sed -E 's/.*\..*\.(.*)$/\1/')"
	OUTPUT="$(echo $FILE_NAME | sed -E 's/(.*)\..*\..*$/\1/')"

	if $VERBOSE
	then
		echo LINE: $LINE
		echo FULL_NAME: $FULL_NAME
		echo FILE_PATH: $FILE_PATH
		echo FILE_NAME: $FILE_NAME
		echo CHECKSUM: $CHECKSUM
		echo POSTFIX: $POSTFIX
		echo OUTPUT: $OUTPUT
	fi

	FULL_OUTPUT_PATH="${OUTPUT_DIR}/${FILE_PATH}/${OUTPUT}"
	if [ -z "${FILE_PATH}" ]
	then
		FULL_OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT}"
	fi

	FILE_LIST[$FILE_LIST_INDEX]=$FULL_OUTPUT_PATH
	FILE_LIST_INDEX=$((FILE_LIST_INDEX + 1))

	if [ -n "$(echo $FILE_PATH | grep Cache.Windows)" ]
	then
		$VERBOSE && echo skipping "$FULL_OUTPUT_PATH" for warframe to handle patching
		continue
	fi

	# verify existing files
	if [ -f "$FULL_OUTPUT_PATH" ]
	then
		$VERBOSE && echo "$FULL_OUTPUT_PATH" exists, checking checksum
		EXISTING_CHECKSUM=$(MD5SUM "$FULL_OUTPUT_PATH")
		if [ "${EXISTING_CHECKSUM^^}" == "$CHECKSUM" ]
		then
			$VERBOSE && echo "$FULL_OUTPUT_PATH" is already the latest version
			continue
		else
			echo "$FULL_OUTPUT_PATH" has to be updated
		fi
	fi

	# download file
	echo downloading $FULL_OUTPUT_PATH
	! [ -d "${OUTPUT_DIR}/${FILE_PATH}" ] && mkdir -p "${OUTPUT_DIR}/${FILE_PATH}"
	case "$POSTFIX" in
		"lzma")
			$CURL "${BASE_URL}/${FULL_NAME}" | $LZCAT > "$FULL_OUTPUT_PATH"
			;;
		"bulk")
			$CURL "${BASE_URL}/${FULL_NAME}" > "$FULL_OUTPUT_PATH"
			;;
		*)
			echo unknown postfix ${POSTFIX}, interrupting
			exit 1
			;;
	esac

	# verify downloaded file
	echo verifying $FULL_OUTPUT_PATH
	DOWNLOADED_CHECKSUM=$(MD5SUM "$FULL_OUTPUT_PATH")
	if [ "${DOWNLOADED_CHECKSUM^^}" != "$CHECKSUM" ]
	then
		echo warning: $FULL_OUTPUT_PATH checksum does not match index
		echo warning: $FULL_OUTPUT_PATH checksum does not match index >> file_errors.txt
	fi
done < <(echo "$INDEX")

# clean existing files against file list
file_in_list () {
	INDEX=0
	while [ $INDEX -lt $FILE_LIST_INDEX ]
	do
		if [ "${FILE_LIST[$INDEX]}" == "$1" ]
		then
			return 0
		fi
		INDEX=$((INDEX + 1))
	done
	return 1
}

echo removing files that are not in index
while read -r LINE
do
	if ! file_in_list "$LINE"
	then
		echo "$LINE" is not in index anymore, removing
		rm "$LINE"
	fi
done < <(find "$OUTPUT_DIR" -type f)

echo using warframe exe to pull in game caches
echo this will take a while
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -silent -log:/Preprocess.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/ContentUpdate
)
