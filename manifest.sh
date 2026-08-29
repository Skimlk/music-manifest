#!/bin/bash

LIST_FILE="songlist"
SONG_DIR="songs"

print_usage() {
	echo "Usage: $0 <command>"
	echo "Commands:"
	echo "  download"
	echo "  add [\"Artist - Title\" ...]"
}

download() {
	sockseek $LIST_FILE \
		--input-type=list \
		--song \
		--extract-artist \
		--strict-artist \
		--strict-title \
		--name-format "{artist} - {title}" \
		--no-incomplete-ext \
		--skip-music-dir $SONG_DIR \
		--skip-mode-music-dir tag \
		-o "$SONG_DIR"
}

add() {
	added=()
	for song in "$@"; do
		if grep -qxF "$song" "$LIST_FILE"; then
			echo "Already in list, skipping: $song"
			continue
		fi
		echo "\"$song\"" >> $LIST_FILE
		added+=("$song")
	done

	if [ "${#added[@]}" -eq 0 ]; then
		echo "Nothing new to add."
		exit 0
	fi

	sort -u -o "$LIST_FILE" "$LIST_FILE"

	git add "$LIST_FILE"
	printf -v song_list '%s, ' "${added[@]}"
	song_list="${song_list%, }"
	git commit -m "Added: $song_list"
	git push	

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
