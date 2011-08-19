cat /root/rebuilder/newer_depends.txt \
	| grep -Ef /root/rebuilder/broken.regex \
	| bash /root/rebuilder/depend_to_package.sh \
	>| /root/rebuilder/brokens.out


