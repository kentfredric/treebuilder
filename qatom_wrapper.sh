#!/bin/bash
export LC_ALL=C
if [[ "$@" == "" ]];
then
  echo -n '';
else
  exec qatom -q -C $@;
fi

