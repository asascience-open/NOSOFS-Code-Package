#!/bin/sh

# ############################################################################
#  Script Name:  exnos_ofs_nowcast_forecast.sh.sms 
#  Purpose:                                                                   #
#  This is the main script is launch both nowcast and forecast simulations    #
# Location:   ~/jobs
# Technical Contact:    Aijun Zhang         Org:  NOS/CO-OPS
#                       Phone: 301-7132890 ext. 127
#                       E-Mail: aijun.zhang@noaa.gov
#
# Usage: 
#
# Input Parameters:
#  OFS 
#
# Modification History:
#     Degui Cao     02/18/2010   
# ##########################################################################

set -x
#PS4=" \${SECONDS} \${0##*/} L\${LINENO} + "

#  Control Files For Model Run
if [ -s ${FIXofs}/${PREFIXNOS}.ctl ]
then
  . ${FIXofs}/${PREFIXNOS}.ctl
  if [ -n "$LSB_DJOB_NUMPROC" ] && [ $TOTAL_TASKS -ne $LSB_DJOB_NUMPROC ]; then
    err_exit "Number of tasks/CPUs ($LSB_DJOB_NUMPROC) does not meet job requirements (see ${FIXofs}/${PREFIXNOS}.ctl)."
  fi
else
  echo "${RUN} control file is not found, FATAL ERROR!"
  echo "please provide  ${RUN} control file of ${PREFIXNOS}.ctl in ${FIXofs}"
  msg="${RUN} control file is not found, FATAL ERROR!"
  postmsg "$jlogfile" "$msg"
  postmsg "$nosjlogfile" "$msg"
  msg="please provide  ${RUN} control file of ${PREFIXNOS}.ctl in ${FIXofs}"
  postmsg "$jlogfile" "$msg"
  postmsg "$nosjlogfile" "$msg"
  echo "${RUN} control file is not found, FATAL ERROR!"  >> $cormslogfile
  err_chk
fi

echo "run the launch script to set the NOS configuration"
. $USHnos/nos_ofs_launch.sh $OFS forecast
export pgm="$USHnos/nos_ofs_launch.sh $OFS forecast"

export err=$?
if [ $err -ne 0 ]
then
   echo "Execution of $pgm did not complete normally, FATAL ERROR!"
   echo "Execution of $pgm did not complete normally, FATAL ERROR!" >> $cormslogfile
   msg=" Execution of $pgm did not complete normally, FATAL ERROR!"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
   err_chk
else
   echo "Execution of $pgm completed normally" >> $cormslogfile
   echo "Execution of $pgm completed normally"
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
fi

#PT if [ $DO_NOWCAST -eq 1 ]; then
#PT #####     Run nowcast simulation
#PT runtype='nowcast'
#PT echo "     " >> $jlogfile 
#PT echo "     " >> $nosjlogfile 
#PT echo " Start $runtype " >> $jlogfile
#PT echo " Start $runtype " >> $nosjlogfile
#PT echo "Making $runtype at : `date`" >> $jlogfile
#PT echo "Making $runtype at : `date`" >> $nosjlogfile
#PT echo "Making $runtype at : `date`"
#PT export pgm="$USHnos/nos_ofs_nowcast_forecast.sh $runtype"
#PT $USHnos/nos_ofs_nowcast_forecast.sh $runtype 
#PT export err=$?
#PT if [ $err -ne 0 ]
#PT then
#PT    echo "Execution of $pgm did not complete normally, FATAL ERROR!"
#PT    echo "Execution of $pgm did not complete normally, FATAL ERROR!" >> $cormslogfile
#PT    msg=" Execution of $pgm did not complete normally, FATAL ERROR!"
#PT    postmsg "$jlogfile" "$msg"
#PT    postmsg "$nosjlogfile" "$msg"
#PT    err_chk
#PT else
#PT    echo "Execution of $pgm completed normally" >> $cormslogfile
#PT    echo "Execution of $pgm completed normally"
#PT    msg=" Execution of $pgm completed normally"
#PT    postmsg "$jlogfile" "$msg"
#PT    postmsg "$nosjlogfile" "$msg"
#PT fi
#PT 
#PT ###  archive nowcast outputs
#PT export pgm="$USHnos/nos_ofs_archive.sh $runtype"
#PT $USHnos/nos_ofs_archive.sh $runtype
#PT export err=$?
#PT if [ $err -ne 0 ]
#PT then
#PT    echo "Execution of $pgm did not complete normally, FATAL ERROR!"
#PT    echo "Execution of $pgm did not complete normally, FATAL ERROR!" >> $cormslogfile
#PT    msg=" Execution of $pgm did not complete normally, FATAL ERROR!"
#PT    postmsg "$jlogfile" "$msg"
#PT    postmsg "$nosjlogfile" "$msg"
#PT    err_chk
#PT else
#PT    echo "Execution of $pgm completed normally" >> $cormslogfile
#PT    echo "Execution of $pgm completed normally"
#PT    msg=" Execution of $pgm completed normally"
#PT    postmsg "$jlogfile" "$msg"
#PT    postmsg "$nosjlogfile" "$msg"
#PT fi
#PT 
#PT # if [ $envir = "dev" ]; then
#PT #   $USHnos/nos_ofs_sftp.sh $runtype
#PT # fi
#PT  echo "end of $runtype"
#PT 

if [ $LEN_FORECAST -gt 0 ] 
then
#####    Run forecast simulation
runtype='forecast'

echo "     " >> $jlogfile 
echo "     " >> $nosjlogfile 
echo " Start nos_ofs_nowcast_forecast.sh $runtype at : `date`" >> $jlogfile
echo " Start nos_ofs_nowcast_forecast.sh $runtype at : `date`" >> $nosjlogfile
echo "Running nos_ofs_nowcast_forecast.sh $runtype at : `date`" >> $jlogfile
echo "Running nos_ofs_nowcast_forecast.sh $runtype at : `date`" >> $nosjlogfile
echo " Start nos_ofs_nowcast_forecast.sh $runtype at : `date`" 
export pgm="$USHnos/nos_ofs_nowcast_forecast.sh $runtype"
$USHnos/nos_ofs_nowcast_forecast.sh $runtype 
export err=$?
if [ $err -ne 0 ]
then
   echo "Execution of $pgm did not complete normally, FATAL ERROR!"
   echo "Execution of $pgm did not complete normally, FATAL ERROR!" >> $cormslogfile
   msg=" Execution of $pgm did not complete normally, FATAL ERROR!"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
   err_chk
else
   echo "Execution of $pgm completed normally" >> $cormslogfile
   echo "Execution of $pgm completed normally"
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
fi
echo "end of nos_ofs_nowcast_forecast.sh $runtype"

##  archive forecast outputs 
export pgm="$USHnos/nos_ofs_archive.sh $runtype"
#PT Skipping this for Sandbox
#PT $USHnos/nos_ofs_archive.sh $runtype 
export err=$?
if [ $err -ne 0 ]
then
   echo "Execution of $pgm did not complete normally, FATAL ERROR!"
   echo "Execution of $pgm did not complete normally, FATAL ERROR!" >> $cormslogfile
   msg=" Execution of $pgm did not complete normally, FATAL ERROR!"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
   err_chk
else
   echo "Execution of $pgm completed normally" >> $cormslogfile
   echo "Execution of $pgm completed normally"
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
   postmsg "$nosjlogfile" "$msg"
fi

# if [ $envir = "dev" ]; then
#  # for development copy outputs to CO-OPS via sftp push 
#   $USHnos/nos_ofs_sftp.sh $runtype
# fi
if [ $SENDDBN = YES ]; then
  $DBNROOT/bin/dbn_alert MODEL $DBN_ALERT_TYPE_TEXT $job $nosjlogfile
fi
fi
          echo "                                    "
          echo "END OF NOWCAST/FORECAST SUCCESSFULLY"
          echo "                                    "
###############################################################
