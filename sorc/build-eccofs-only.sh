#!/bin/sh
# set -x 
set -e

#############################################################################
#                                                                             #
# Compiles source codes of nosofs, moves executables to exec and cleans up    #
#Usage:                                                                       #
# ./build.sh     - build executable with normal options                       #
# ./build.sh debug  - build executable with debug options                     #
#                                                                 June 2024   #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
#HOMEnos=/lfs/h1/nos/nosofs/noscrub/$LOGNAME/packages/nosofs.v3.7.2

export HOMEnos=$(dirname $PWD)

# 1. Preparations - load required modules, set compilers, and set pathnames

BUILD_VERSION_FILE=$HOMEnos/versions/build.ver
if [ -f $BUILD_VERSION_FILE ]; then
 . $BUILD_VERSION_FILE
else
   echo " Build Version File $BUILD_VERSION_FILE does not exist **"
   exit
fi

export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

module purge
printenv SHELL

module use -a $HOMEnos/modulefiles
module load intel_x86_64

if [ ! -s $EXECnos ]
then
  mkdir -p $EXECnos
fi

if [ ! -s $LIBnos ]
then
  mkdir -p $LIBnos
fi


# 2. Create all executions of nosofs framework (COMF) 
cd $SORCnos
fcodes=`ls -d nos*.fd | sed 's/\.fd//g'`
echo "fcodes: "
echo "$fcodes"

# only building a subset
fcodes="
nos_ofs_adjust_tides
nos_ofs_met_file_search
nos_ofs_read_restart
nos_ofs_reformat_ROMS_CTL
nos_ofs_rename
"

echo " FORTRAN codes found: "${fcodes}.f
if [ $# -eq 0 ]; then

  # nos_ofs_utility has to be compiled first because libnosutil.a is used by other Fortran codes	
  cd $SORCnos/nos_ofs_utility.fd
  make clean
  make
  result=$?
  if [ $result -ne 0 ]; then
    echo "ERROR building nos_ofs_utility.fd"
    exit $result
  else
    echo "SUCCESS: nos_ofs_utility.fd built"
  fi
  make install
  make clean

  for code in $fcodes ; do
    if [ $code != "nos_ofs_utility" ]; then	   
      echo ""
      echo ""
      echo "Creating $code "
      echo "-------------------------------------"
      echo "-------------------------------------"
      cd $SORCnos/${code}.fd
      make clean
      make 
      result=$?
      if [ $result -ne 0 ]; then
        echo "ERROR building ${code}.fd"
        exit $result
      else
        echo "SUCCESS: ${code}.fd built"
      fi
      make install
      make clean
    fi  
  done   
fi


# 3. Create all executions with debug for nosofs framework (COMF)
if [ "$1" = "debug" ]; then
#  nos_ofs_utility has to be compiled first because libnosutil.a is used by other Fortran codes
   cd $SORCnos/nos_ofs_utility.fd
   make clean
   make DEBUG=full
   make install
   make clean
   for code in $fcodes ; do
     if [ $code != "nos_ofs_utility" ]; then
       echo "Creating $code "
       cd $SORCnos/${code}.fd
       make clean
       make DEBUG=full
       make install
       make clean
     fi
   done
fi


# 4. Compile ocean model for ECCOFS
cd $SORCnos/ROMS.eccofs
./COMPILE_ROMS.sh


