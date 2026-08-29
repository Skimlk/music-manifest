#!/bin/bash

LIST_FILE="songlist"
SONG_DIR="songs"
DOWNLOAD_LIST_FILE="downloaded"
DOWNLOAD_COMMAND="sockseek --song -o $SONG_DIR"

print_usage() {
	echo "Usage: $0 <command>"
	echo "Commands:"
	echo "  download"
	echo "  add [\"Artist - Title\" ...]"
}

download() {
	while IFS= read -r song; do
		[ -z "$song" ] && continue
		if grep -qxF "$song" "$DOWNLOAD_LIST_FILE" 2>/dev/null; then
			continue
		fi
		if $DOWNLOAD_COMMAND "$song"; then
			echo "$song" >> "$DOWNLOAD_LIST_FILE"
		fi
	done < "$LIST_FILE"
}

add() {
	added=()
	for song in "$@"; do
		if grep -qxF "$song" "$LIST_FILE"; then
			echo "Already in list, skipping: $song"
			continue
		fi
		echo "$song" >> $LIST_FILE
		added+=("$song")
	done

	if [ "${#added[@]}" -eq 0 ]; then
		echo "Nothing new to add."
		exit 0
	fi

	git add "$LIST_FILE"
	printf -v song_list '%s, ' "${added[@]}"
	song_list="${song_list%, }"
	git commit -m "Added $song_list"

	download
}

if [ "$#" -eq 0 ]; then
	print_usage
	exit 1
fi

if declare -F $1 > /dev/null; then
	command="$1"
	shift
	"$command" "$@"
	exit
fi

print_usage
exit 1
