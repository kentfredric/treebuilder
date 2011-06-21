sed -e 's|^.*pkg/||' \
	-e 's|/[^/]*$||' \
	| sort -u \
	| xargs qatom \
	| cut -d" " -f 1,2 \
	| sed -e 's| |/|' \
	| sort -u
