export LC_ALL=C
perl ./generate_rebuilds.pl
#./newer_depends_than.pl
#./broken_2_regex.sh
#./rebuild_2_regex.sh
#./generate_rebuilds.sh
#./generate_brokens.sh
echo -e "\e[31m##\e[0m"
RED="$(  echo -en "\e[31m" )";
GREEN="$(  echo -en "\e[32m" )";
RESET="$( echo -en "\e[0m" )";
diff -Naur broken.txt brokens.out | sed -r -e "s/^-(.*$)/${RED}-\1${RESET}/" -e "s/^\+(.*$)/${GREEN}+\1${RESET}/"
#cat brokens.out rebuilds.out | sort -u > brokens.all
#cat brokens.out rebuilds.out | sort | uniq -d > brokens.duplicate
#cat brokens.out rebuilds.out | sort | uniq -u > brokens.unique
echo -e "\e[31m##\e[0m"
#shuf -n 20 --random-source=/tmp/rand  rebuilds.out
wc -l rebuilds.out 

