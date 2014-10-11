grep 'dev-perl\|virtual/perl-\|perl-core/' ./broken.txt | shuf -n $1 --random-source=./broken.txt

