perl ./auto_success_grep.pl
bash ./sync.sh
mv brokens.all broken.txt
bash ./mk_timestamp.sh
echo > rebuild.txt

