./newer_depends_than.sh
./broken_2_regex.sh
./rebuild_2_regex.sh
./generate_rebuilds.sh
echo "##"
shuf -n 20 --random-source=/tmp/rand  rebuilds.out
wc -l rebuilds.out 

