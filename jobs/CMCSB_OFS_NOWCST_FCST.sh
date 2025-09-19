#!/bin/sh
#set -x

# Coastal Modeling Cloud Sandbox - adapted from JNOS_OFS_NOWCST_FCST

if [ $# -ne 2 ] ; then
  echo "Usage: $0 YYYYMMDD HH"
  exit 1
fi

export CDATE=$1
HH=$2

export HOMEnos=$(dirname $PWD)

# YES will not delete /ptmp run directory, useful when debugging
export KEEPDATA=NO
#export KEEPDATA=YES

NOWCAST=NO      # Run the nowcast?
FORECAST=YES    # Run the forecast?

# Use the intel OFI library
export I_MPI_OFI_LIBRARY_INTERNAL=1
# Will display the fabric details when run starts
export I_MPI_DEBUG=1

# Make metis and other libraries visible by ld
export LD_LIBRARY_PATH=$HOMEnos/lib:$LD_LIBRARY_PATH

module use -a $HOMEnos/modulefiles
module load intel_x86_64
module list

export OFS=${OFS:-cbofs}
export PREFIXNOS=$OFS

NOWCAST=${NOWCAST:-NO}      # Run the nowcast?
FORECAST=${FORECAST:-YES}    # Run the forecast?

export NODES=${NODES:-1}
export NPP=${NPP:-16}     # Number of processors
export PPN=${PPN:-$((NPP/NODES))}

export HOSTFILE=${HOSTFILE:-$PWD/hosts}
export SENDDBN=NO

export MPIEXEC=mpirun

if [[ "$OFS" == "ngofs2" ]] ; then
  export MPIOPTS=${MPIOPTS:-"-np $NPP -ppn $PPN -bind-to core"}
fi

export MPIOPTS=${MPIOPTS:-"-np $NPP -ppn $PPN "}

export cyc=${HH}
export nosofs_ver=v3.6.6
export NWROOT=/save
export COMROOT=/com
export DATA=$PTMP/$OFS.${CDATE}${HH}
export jobid=fcst.$$


########################################
# NOS_OFS_NOWCST_FCST 
########################################
export PS4=' $SECONDS + '
date
export HOMEnos=${HOMEnos:-${PACKAGEROOT}/nosofs.${nosofs_ver}}
###################################
# Specify NET and RUN Name and model
####################################
export NET=${NET:-nosofs}
export RUN=${RUN:-$OFS}
export PREFIXNOS=${PREFIXNOS:-$OFS}
# hardcoded SENDDBN = NO for wcofs_da and wcofs_free
export SENDDBN=${SENDDBN:-NO}
if [ "${OFS,,}" == "wcofs_da" -o "${OFS,,}" == "wcofs_free" ]; then
   export SENDDBN='NO'
fi

###############################################################
# Specify DBN_ALERT_TYPE_???? for different Production envir.
###############################################################
export DBN_ALERT_TYPE_NETCDF=${DBN_ALERT_TYPE_NETCDF:-NOS_OFS_FCST_NETCDF}
export DBN_ALERT_TYPE_NETCDF_LRG=${DBN_ALERT_TYPE_NETCDF_LRG:-NOS_OFS_FCST_NETCDF_LP}
export DBN_ALERT_TYPE_TEXT=${DBN_ALERT_TYPE_TEXT:-NOS_OFS_FCST_TEXT}

export cycle=t${cyc}z

########################################################
# Make working directory
########################################################
#export DATAROOT=${DATAROOT:-/lfs/f1/ops/${evnir}/tmp}
export DATA=${DATA:-${DATAROOT:?}/nos_${OFS}_nf_${cyc}_${envir}_${nosofs_ver}}
if [ ! -d $DATA ]; then
  mkdir -p $DATA
  cd $DATA
else
  cd $DATA
#  rm -fr $DATA/* ## DO NOT DELETE FILES IN CASE RESTARTing FORECAST
#                 This directory should be removed at the end of this script if the run completes successfully
fi

############################################
#   Determine Job Output Name on System
############################################
export pgmout="OUTPUT.$$"
export jlogfile=${jlogfile:-${DATA}/jlogfile}

####################################
# Specify Execution Areas
####################################
export EXECnos=${EXECnos:-${HOMEnos}/exec}
export FIXnos=${FIXnos:-${HOMEnos}/fix/shared}
export FIXofs=${FIXofs:-${HOMEnos}/fix/${OFS}}
export PARMnos=${PARMnos:-${HOMEnos}/parm}
export USHnos=${USHnos:-${HOMEnos}/ush}
export SCRIPTSnos=${SCRIPTSnos:-${HOMEnos}/scripts}
export PYnos=${PYnos:-${HOMEnos}/ush/pysh}

#PT export LD_PRELOAD=${NETCDF_LIBRARIES}/libnetcdff.so:${LD_PRELOAD}

#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${NOSLIBS_DIR}/proj.4-master/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${HOMEnos}/sorc/FVCOM.fd/FVCOM_source/libs/proj.4-master/lib64

###########################################
# Run setpdy and initialize PDY variables
###########################################
# If CDATE is defined, use it (hindcast)
if [[ $CDATE ]] ; then
  export PDY=$CDATE
else
  setpdy.sh
  . ./PDY
fi

export time_nowcastend=$PDY${cyc}
##############################################
# Define COM directories
##############################################
export COMROOT=${COMROOT:-/lfs/h1/ops/${envir}/com}
export DCOMROOT=${DCOMROOT:-/lfs/h1/ops/${envir}/dcom}
export COMIN=${COMIN:-$(compath.py ${NET}/${nosofs_ver})/${RUN}.${PDY}}
export COMOUTroot=${COMOUTroot:-$(compath.py -o ${NET}/${nosofs_ver})}
export COMOUT=${COMOUT:-$(compath.py -o ${NET}/${nosofs_ver})/${RUN}.${PDY}}

export DCOMINndfd=${DCOMROOT}
export DCOMINncom=${DCOMROOT}
export DCOMINusgs=${DCOMROOT}
export DCOMINports=${DCOMROOT}
export NOSBUFR=xx012
export USGSBUFR=xx009
export CANADAWLBUFR=xx021   ## wl Cananda
export CANADARVBUFR=xx022  # river Canada


mkdir -m 775 -p $COMOUT

if [ "${OFS,,}" == "wcofs_da" ]; then
   export OFS_NF='wcofs'
   export COMrst=${COMOUTroot}
fi

##############################################
####  Log File To Sys Report  
##############################################
export nosjlogfile=${COMOUT}/${PREFIXNOS}.${cycle}.${PDY}.jlogfile.log 

##############################################
####  Log File To CORMS
##############################################
export cormslogfile=${COMOUT}/${PREFIXNOS}.${cycle}.${PDY}.corms.log
set +x
echo "LAUNCH ${RUN} NOWCAST/FORECAST SIMULATIONS at time: " `date ` >> $cormslogfile
echo "NOWCAST/FORECAST CYCLE IS: " $time_nowcastend >> $cormslogfile
echo "Start ${RUN} " >> $cormslogfile
set -x

env  
##############################################
# Check if this is for restarting forecast run
##############################################
CONTINUE_FORECAST=NO
CONTINUE_FORECAST_FILE=${RUN}_CONTINUE_FORECAST.t${cyc}z

# for FVCOM-based OFS
NFILE=`find . -name "*${OFS}_restart*.nc" -o -name "*.rst.forecast*.nc" | wc -l`
if [ $NFILE -gt 0 ]; then
    latest_restart_f=`ls -al *${OFS}_restart*.nc *.rst.forecast*.nc | tail -1 | awk '{print $NF}' `
else
   latest_restart_f='blank'
fi
#

if [ -s  $latest_restart_f ]; then
  echo "FOUND restart file for continuous forecast run"
  CONTINUE_FORECAST=YES
fi
export CONTINUE_FORECAST
########################################################
# Execute the script.
########################################################

#PT if [ $CONTINUE_FORECAST == 'NO' ]; then
#PT   $SCRIPTSnos/exnos_ofs_nowcast_forecast.sh $OFS
#PT else
#PT   $SCRIPTSnos/exnos_ofs_continue_forecast.sh $OFS
#PT fi

if [[ $NOWCAST == "YES" ]] ; then

  $SCRIPTSnos/exnos_ofs_nowcast.sh $OFS
  result=$?

  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  #echo "    FINISHED NOWCAST FOR $CDATE $cycle               "
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
fi


if [[ $FORECAST == "YES" ]] ; then

  $SCRIPTSnos/exnos_ofs_forecast.sh $OFS
  result=$?

  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "    FINISHED FORECAST FOR $CDATE $cycle               "
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  echo "-----------------------------------------------------"
  ########################################################
fi

cat $pgmout

postmsg "$jlogfile" "$0 completed normally"

# Save any log files
cp -p $DATA/*.log $COMOUT

##############################
# Remove the Temporary working directory
##############################
if [ "${KEEPDATA^^}" != YES ]; then
  rm -rf $DATA
fi

if [[ $envir == 'dev' ]]; then
  RPTDIR=/lfs/h1/nos/ptmp/$LOGNAME/rpt/${nosofs_ver}
  cp -p ${RPTDIR}/${OFS}_nf_${cyc}.out ${RPTDIR}/${OFS}_nf_${cyc}.out.${pbsid}
  cp -p ${RPTDIR}/${OFS}_nf_${cyc}.err ${RPTDIR}/${OFS}_nf_${cyc}.err.${pbsid}
fi

date
exit $result


