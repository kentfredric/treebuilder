date +%Y%m%d%H%M.%S >| /root/rebuilder/timestamp.d
touch -t "$(cat /root/rebuilder/timestamp.d)" /root/rebuilder/timestamp.x
