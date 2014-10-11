grep 'dev-perl' ./broken.txt | shuf -n $1 --random-source=./broken.txt

