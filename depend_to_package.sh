sed -e 's|^.*pkg/||' \
	-e 's|/[^/]*$||' \
	| sort -u \
	| xargs /root/rebuilder/qatom_wrapper.sh \
	| cut -d" " -f 1,2 \
	| sed -e 's| |/|' \
	| sort -u
