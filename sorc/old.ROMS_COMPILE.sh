#!/bin/bash
# set -x

export nosofs_ver=3.5.0
HOMEnos=$(dirname $PWD)
export HOMEnos=${HOMEnos:-${NWROOT:?}/nosofs.${nosofs_ver:?}}

module purge
source /opt/rh/gcc-toolset-11/enable

. /save/environments/spack/share/spack/setup-env.sh

module use $HOMEnos/modulefiles
#module load intel_skylake_512
module load intel_x86_64

module list 2>&1

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

if [ ! -s $EXECnos ]
then
  mkdir -p $EXECnos
fi
export LIBnos=$HOMEnos/lib

if [ ! -s $LIBnos ]
then
  mkdir -p $LIBnos
fi

cd $SORCnos

buildprep=no

#models='cbofs ciofs dbofs gomofs tbofs wcofs wcofs_free'
#models='wcofs'
models='eccofs'

# Needed in post
cd $SORCnos/nos_ofs_rename.fd
rm -f *.o *.a
gmake -f makefile

for model in $models
do
  if [[ $model == "eccofs" ]]; then
    cd $SORCnos/ROMS.eccofs
  else
    cd $SORCnos/ROMS.fd
  fi
  gmake clean
  ./build_${model}.sh 
  if [ -s ${model}_roms_mpi ]; then
    mv ${model}_roms_mpi $EXECnos/.
  else
    echo "roms executable for ${model^^} is not created"
  fi
done

# Compile WCOFS_DA
build_wcofsda="no"
if [[ $build_wcofsda == "yes" ]]; then
  cd $SORCnos/ROMS.fd/Lib/ARPACK
  gmake clean
  gmake  lib
  gmake  plib
  gmake clean
  cd $SORCnos/ROMS.fd
  ./build_wcofs_da.sh
  gmake clean
  if [ -s  wcofs_da_roms_mpi ]; then
    mv wcofs_da_roms_mpi $EXECnos/.
  else
    echo 'roms executable for WCOFS_DA is not created'
  fi
fi


if [[ $buildprep == "yes" ]] ; then

  cd $SORCnos/nos_ofs_utility.fd
  rm -f *.o *.a
  gmake -f makefile
  if [ -s $SORCnos/nos_ofs_utility.fd/libnosutil.a ]
  then
    chmod 755 $SORCnos/nos_ofs_utility.fd/libnosutil.a
    mv $SORCnos/nos_ofs_utility.fd/libnosutil.a ${LIBnos}
  fi

 
  cd $SORCnos/nos_ofs_create_forcing_met.fd
  rm -f *.o *.a
  gmake -f makefile


  cd $SORCnos/nos_ofs_create_forcing_obc_tides.fd
  rm -f *.o *.a
  gmake -f makefile
 
 
  cd $SORCnos/nos_ofs_create_forcing_obc.fd
  rm -f *.o *.a
  gmake -f makefile
 
 
  cd $SORCnos/nos_ofs_create_forcing_river.fd
  rm -f *.o *.a
  gmake -f makefile
 

  cd $SORCnos/nos_ofs_met_file_search.fd
  rm -f *.o *.a
  gmake -f makefile
 

  cd $SORCnos/nos_ofs_read_restart.fd
  rm -f *.o *.a
  gmake -f makefile
 

  cd $SORCnos/nos_ofs_reformat_ROMS_CTL.fd
  rm -f *.o *.a
  gmake -f makefile


 # Unlear which model requires this
  cd $SORCnos/nos_ofs_create_forcing_nudg.fd
  gmake clean
  gmake -f makefile


  cd $SORCnos/nos_ofs_residual_water_calculation.fd
  gmake clean
  gmake -f makefile


  # Not sure if this is ROMS related or not
  cd $SORCnos/nos_ofs_adjust_tides.fd
  gmake clean
  gmake -f makefile

fi  # end if buildprep
