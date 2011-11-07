cave -c y \
	resolve \
	-km \
	-Kn \
	-sa \
	$( grep -vFf brokens.skip rebuilds.out ) \
	--permit-uninstall "*/*" \
	--permit-downgrade "*/*" \
	--permit-old-version "*/*" \
	--continue-on-failure if-independent \
	-J 0 \
	"$@"
