#!/bin/bash
# --------------------------
# name
#$ -N spec
#
# use the current working directory
#$ -cwd
#
# request 311 slots
#$ -pe mvapich2 30
#
#$ -v MPI_HOME=/usr/local/Packages/mvapich2-1.6
# -v MPI_HOME=/usr/local/Packages/openmpi-1.2.8-intel
#

echo "Got $NSLOTS slots."
PATH=$PATH:$MPI_HOME/bin
export MPD_CON_EXT=$JOB_ID
mpiexec -machinefile $TMPDIR/machines  -n $NSLOTS $PWD/spec
