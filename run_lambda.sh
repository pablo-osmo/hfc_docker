#!/bin/bash

while getopts v:u:r:n:l:d; flag
do
    case "${flag}" in
        v) SOLV_NAME=${OPTARG};;
        u) SOLU_NAME=${OPTARG};;
        r) RES_NAME=${OPTARG};;
        n) NUM_MOL=${OPTARG};;
        l) BOX_LEN=${OPTARG};;
        d) LAMBDA=${OPTARG};;
    esac
done

#go into hfc_ops/general_mdp
export HOMEDIR=$PWD/..
echo "solvname and soluname"
echo ${SOLV_NAME} ${SOLU_NAME}

# Set some environment variables 
#-----FREE_ENERGY is where the solvated boxes are
FREE_ENERGY=${HOMEDIR}/solvate/${SOLV_NAME}/${SOLU_NAME}
#-----WORKDIR is where the free energy lambda directories will be made
WORKDIR=${HOMEDIR}/full_tests/${SOLV_NAME}/${SOLU_NAME}
echo "Free energy home directory set to $FREE_ENERGY"
MDP=${FREE_ENERGY}/../../../general_mdp
echo ".mdp files are stored in $MDP"

# THIS $GMX/gmx executable would be replaced with the GROMACS docker call 
GMX=/home/pablo/repos/gromacs_tar/bin/gmx
#something like GMX="docker run -v $HOME/data:/data -w /data -it gromacs/gromacs gmx"

mkdir -p ${WORKDIR}
cd ${WORKDIR}
LAMBDA=$i

# A new directory will be created for each value of lambda and
# at each step in the workflow for maximum organization.

mkdir Lambda_$LAMBDA
cd Lambda_$LAMBDA

##############################
# ENERGY MINIMIZATION STEEP  #
##############################
echo "Starting minimization for lambda = $LAMBDA..." 

mkdir EM
cd EM

# Iterative calls to grompp and mdrun to run the simulations

$GMX grompp -f $MDP/min_$LAMBDA.mdp -c $FREE_ENERGY/solvated.gro -p $FREE_ENERGY/solvated_top.top -o min$LAMBDA.tpr -maxwarn 1
$GMX mdrun -deffnm min$LAMBDA

sleep 10

#####################
# NVT EQUILIBRATION #
#####################
echo "Starting constant volume equilibration..."

cd ../
mkdir NVT
cd NVT

$GMX/gmx grompp -f $MDP/nvt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -o nvt$LAMBDA.tpr
$GMX/gmx mdrun -deffnm nvt$LAMBDA
echo "Constant volume equilibration complete."

sleep 10

#####################
# NPT EQUILIBRATION #
#####################
echo "Starting constant pressure equilibration..."

cd ../
mkdir NPT
cd NPT

$GMX grompp -f $MDP/npt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -o npt$LAMBDA.tpr -maxwarn 1
$GMX mdrun -deffnm npt$LAMBDA
echo "Constant pressure equilibration complete."

sleep 10

#################
# PRODUCTION MD #
#################
echo "Starting production MD simulation..."

cd ../
mkdir Production_MD
cd Production_MD

$GMX grompp -f $MDP/md_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 1
$GMX mdrun -deffnm md$LAMBDA
echo "Production MD complete."

#################
#      END      #
#################
echo "-------------------------------------Ending. Job completed for lambda = $LAMBDA -------------------------------------"
cd $HOMEDIR
exit;