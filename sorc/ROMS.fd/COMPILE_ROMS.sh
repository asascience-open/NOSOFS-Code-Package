#!/bin/sh
export nosofs_ver=3.6.6
export HOMEnos=$(dirname $(dirname $PWD))
export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}

#export HOMEnos=/lfs/h1/nos/nosofs/noscrub/$LOGNAME/packages/nosofs.v3.7.2
#cd ../..
#HOMEnos=`pwd`
#export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}
#export HOMEnos=/lfs/h1/nos/nosofs/noscrub/aijun.zhang/tmp/roms

BUILD_VERSION_FILE=$HOMEnos/versions/build.ver
if [ -f $BUILD_VERSION_FILE ]; then
 . $BUILD_VERSION_FILE
else
   echo " Build Version File $BUILD_VERSION_FILE does not exist **"
   exit
fi

module purge
module use -a $HOMEnos/modulefiles
module load intel_x86_64

# module load envvar/$envvars_ver
## Loading Intel Compiler Suite
#module load PrgEnv-intel/${PrgEnv_intel_ver}
#module load craype/${craype_ver}
#module load intel/${intel_ver}
#module load cray-mpich/${cray_mpich_ver}
#module load cray-pals/${cray_pals_ver}
##Set other library variables
##module load netcdf/${netcdf_ver}
##module load hdf5/${hdf5_ver}
#module load bacio/${bacio_ver}
#module load w3nco/${w3nco_ver}
#module load w3emc/${w3emc_ver}
#module load g2/${g2_ver}
#module load zlib/${zlib_ver}
#module load libpng/${libpng_ver}
#module load bufr/${bufr_ver}
#module load jasper/${jasper_ver}
##
##Set other library variables
#module load netcdf/${netcdf_ver}
#module load hdf5/${hdf5_ver}
#module load subversion/${subversion_ver}

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

models='cbofs ciofs dbofs gomofs tbofs wcofs wcofs_free'

for model in $models
do

  echo ""
  echo "Compiling ROMS ocean model for ${model^^}"
  echo "------------------------------------------------"
  if [[ $model == "eccofs" ]]; then
    cd $SORCnos/ROMS.eccofs
  else
    cd $SORCnos/ROMS.fd
  fi
  gmake clean
  ./build_${model}.sh
  if [ -s ${model}_roms_mpi ]; then
    mv ${model}_roms_mpi $EXECnos/.
    gmake clean
  else
    echo "error: roms executable for ${model^^} is not created"
  fi
done

exit 

# Compile WCOFS_DA
#cd $SORCnos/ROMS.fd/Lib/ARPACK
#gmake clean
#gmake  lib
#gmake  plib
#gmake clean
cd $SORCnos/ROMS.fd
gmake clean
./build_wcofs_da.sh
if [ -s  wcofs_da_roms_mpi ]; then
  mv wcofs_da_roms_mpi $EXECnos/.
else
  echo 'roms executable for WCOFS_DA is not created'
fi
gmake clean


