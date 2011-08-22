export LC_ALL=C;
sed -e '/^\s*#/d' \
	-e '/^\s*$/d' \
	-e 's/$/($|[[:space:]]|[^[:alpha:]]($|[[:space:][:digit:]]))/' \
	/root/rebuilder/broken.txt \
	>| /root/rebuilder/broken.regex


