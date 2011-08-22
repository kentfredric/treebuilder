export LC_ALL=C
sed -e '/^\s*#/d' \
	-e '/^\s*$/d' \
	-e 's/$/($|[[:space:]]|[^[:alpha:]]($|[[:space:][:digit:]]))/' \
	/root/rebuilder/rebuild.txt \
	| sort -u \
	>| /root/rebuilder/rebuild.regex


