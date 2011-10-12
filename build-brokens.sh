cave -c y \
	resolve \
	-km \
	-Kn \
	-sa \
	$( grep -vFf brokens.skip brokens.all ) \
	--permit-uninstall "*/*" \
	--permit-downgrade "*/*" \
	--permit-old-version "*/*" \
	--continue-on-failure if-independent \
	$@
