cat /root/rebuilder/newer_depends.txt \
	| xargs \
		grep -Elf /root/rebuilder/rebuild.regex \
	| tee /dev/stderr \
	| bash /root/rebuilder/depend_to_package.sh \
	| tee /dev/stderr \
	>| /root/rebuilder/rebuilds.out


