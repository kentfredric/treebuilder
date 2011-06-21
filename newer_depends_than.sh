# vim: ts=4:sw=4:et
find -O3 \
	    /var/db/pkg/ \
	    -name "*DEPEND" \
	    -not -newer /root/rebuilder/timestamp.x \
	 | tee /dev/stderr \
    >| /root/rebuilder/newer_depends.txt
