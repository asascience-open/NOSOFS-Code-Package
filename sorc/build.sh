#!/bin/sh
set -x 
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
cd ..
HOMEnos=`pwd`

# 1. Preparations - load required modules, set compilers, and set pathnames

BUILD_VERSION_FILE=$HOMEnos/versions/build.ver
if [ -f $BUILD_VERSION_FILE ]; then
 . $BUILD_VERSION_FILE
else
   echo " Build Version File $BUILD_VERSION_FILE does not exist **"
   exit
fi

export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}

export COMP_F=ftn
export COMP_F_MPI90=ftn
export COMP_F_MPI=ftn
export COMP_ICC=cc
export COMP_CC=cc
export COMP_CPP=cpp
export COMP_MPCC=cc
export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

module purge
printenv SHELL
module purge
module load envvar/$envvars_ver
# Loading Intel Compiler Suite
module load PrgEnv-intel/${PrgEnv_intel_ver}
module load craype/${craype_ver}
module load intel/${intel_ver}
module load cray-mpich/${cray_mpich_ver}
module load cray-pals/${cray_pals_ver}
#Set other library variables
#module load netcdf/${netcdf_ver}
#module load hdf5/${hdf5_ver}
module load bacio/${bacio_ver}
module load w3nco/${w3nco_ver}
module load w3emc/${w3emc_ver}
module load g2/${g2_ver}
module load zlib/${zlib_ver}
module load libpng/${libpng_ver}
module load bufr/${bufr_ver}
module load jasper/${jasper_ver}
#
#Set other library variables
module load netcdf/${netcdf_ver}
module load hdf5/${hdf5_ver}
module load subversion/${subversion_ver}


if [ ! -s $EXECnos ]
then
  mkdir -p $EXECnos
fi
export LIBnos=$HOMEnos/lib

if [ ! -s $LIBnos ]
then
  mkdir -p $LIBnos
fi

# 2. Create all executions of nosofs framework (COMF) 
cd $SORCnos
fcodes=`ls -d nos*.fd | sed 's/\.fd//g'`
echo " FORTRAN codes found: "${fcodes}.f
if [ $# -eq 0 ]; then
#  nos_ofs_utility has to be compiled first because libnosutil.a is used by other Fortran codes	
   cd $SORCnos/nos_ofs_utility.fd
   make clean
   make
   make install
   make clean
   for code in $fcodes ; do
    if [ $code != "nos_ofs_utility" ]; then	   
      echo "Creating $code "
      cd $SORCnos/${code}.fd
      make clean
      make 
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

# 4. Compile ocean models of ROMS-based OFS 
# cbofs, dbofs, tbofs,ciofs, gomofs, wcofs, wcofs_da, wcofs_free
cd $SORCnos/ROMS.fd
./COMPILE_ROMS.sh

# 5. Compile ocean models of FVCOM-based OFS
# leofs, lmhofs, loofs, lsofs, sfbofs,ngfos2, sscofs
cd $SORCnos/FVCOM.fd
./COMPILE_FVCOM.sh

