cave -c y \
	resolve \
		-c \
		-km \
		-Km \
		-sa \
		--permit-downgrade "*/*" \
		--permit-uninstall "*/*" \
		--permit-old-version "*/*" \
	installed-packages "$@"
