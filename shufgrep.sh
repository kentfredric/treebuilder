grep $1 ./broken.txt | shuf -n $2 --random-source=./broken.txt

