#!/bin/bash

if [[ "$@" == "" ]];
then
  echo -n '';
else
  exec qatom -q -C $@;
fi

