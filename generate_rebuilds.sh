export LC_ALL=C
cat /root/rebuilder/newer_depends.txt \
	| xargs \
		grep -Elf /root/rebuilder/rebuild.regex \
	| bash /root/rebuilder/depend_to_package.sh \
	>| /root/rebuilder/rebuilds.out


