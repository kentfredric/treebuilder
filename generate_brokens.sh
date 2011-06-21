cat /root/rebuilder/newer_depends.txt \
	| grep -Ef /root/rebuilder/broken.regex \
	| tee /dev/stderr \
	| bash /root/rebuilder/depend_to_package.sh \
	| tee /dev/stderr \
	>| /root/rebuilder/brokens.out


