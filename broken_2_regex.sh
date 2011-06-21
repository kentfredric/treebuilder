sed -e '/^\s*#/d' \
	-e '/^\s*$/d' \
	-e 's/$/($|[[:space:]]|[^[:alpha:]]($|[[:space:][:digit:]]))/' \
	/root/rebuilder/broken.txt \
	| tee /dev/stderr \
	>| /root/rebuilder/broken.regex


