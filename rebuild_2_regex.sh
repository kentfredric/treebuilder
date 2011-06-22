sed -e '/^\s*#/d' \
	-e '/^\s*$/d' \
	-e 's/$/($|[[:space:]]|[^[:alpha:]]($|[[:space:][:digit:]]))/' \
	/root/rebuilder/rebuild.txt \
	| sort -u \
	| tee /dev/stderr \
	>| /root/rebuilder/rebuild.regex


