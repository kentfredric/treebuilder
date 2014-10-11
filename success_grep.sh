export LC_ALL=C
grep -A 99999 "$@" /var/log/paludis_success.log | \
	grep 'success\s\+install' | \
	sed "s/^.* : //;s/::.*$//;s/-r[\d]*:/:/;s/\(-[0-9.]\+\)\+:/:/"
