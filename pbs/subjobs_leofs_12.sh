#!/bin/bash
. /lfs/h1/nos/nosofs/noscrub/aijun.zhang/packages/nosofs.v3.6.6/versions/run.ver
module load envvar/${envvars_ver:?}
module load PrgEnv-intel/${PrgEnv_intel_ver}
module load craype/${craype_ver}
module load intel/${intel_ver}
if [ ! -d /lfs/h1/nos/ptmp/aijun.zhang/execlog/v3.6.6 ]; then 
   mkdir -p /lfs/h1/nos/ptmp/aijun.zhang/execlog/v3.6.6 
fi 
if [ ! -d /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.6.6 ]; then 
   mkdir -p /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.6.6 
fi 
rm -f /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.6.6/leofs_*_12.out
rm -f /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.6.6/leofs_*_12.err
export LSFDIR=/lfs/h1/nos/nosofs/noscrub/aijun.zhang/packages/nosofs.v3.6.6/pbs 
PREP=$(qsub  $LSFDIR/jnos_leofs_prep_12.pbs) 
NFRUN=$(qsub -W depend=afterok:$PREP $LSFDIR/jnos_leofs_nowcst_fcst_12.pbs)
qsub -W depend=afterok:$NFRUN $LSFDIR/jnos_leofs_aws_12.pbs
