#!/usr/bin/env bash

export CDATE=20190102
export HH=00
export COMOUT=/com/patrick/nosofs/eccofs.20190102
export SAVEDIR=/save/patrick/nosofs.v3.6.6
export PTMP=/ptmp/patrick
export NPROCS=4
export PPN=4
export HOSTS=127.0.0.1
export OFS=eccofs

./fcstrun.sh $CDATE $HH

