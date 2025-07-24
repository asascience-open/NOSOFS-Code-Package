#!/bin/sh
set -ex 

#############################################################################
#                                                                             #
# Cleans the nosofs source, remove previously built libraries and binaries    #
#                                                                 July 2025   #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
#HOMEnos=/lfs/h1/nos/nosofs/noscrub/$LOGNAME/packages/nosofs.v3.7.2
#cd ..
#HOMEnos=`pwd`
export HOMEnos=$(dirname $PWD)

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

if [ -d $EXECnos ]; then
  cd $EXECnos
  rm -f *
fi

if [ -d $LIBnos ]; then
  cd $LIBnos
  rm -f *
fi

cd $SORCnos
fcodes=`ls -d nos*.fd | sed 's/\.fd//g'`
echo " FORTRAN codes found: "${fcodes}.f
if [ $# -eq 0 ]; then
   for code in $fcodes ; do
      echo "Cleaning $code "
      cd $SORCnos/${code}.fd
      make clean
   done
fi

cd $SORCnos/ROMS.fd
make clean

cd $SORCnos/FVCOM.fd/FVCOM_source
make clean

cd $SORCnos/FVCOM.fd/FVCOM_source.prod
make clean

