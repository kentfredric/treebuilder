sed -e '/^\s*#/d' \
	-e '/^\s*$/d' \
	-e 's/$/($|[[:space:]]|[^[:alpha:]]($|[[:space:][:digit:]]))/' \
	/root/rebuilder/rebuild.txt \
	| tee /dev/stderr \
	>| /root/rebuilder/rebuild.regex


