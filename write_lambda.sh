#!/bin/bash

while getopts v:u:r:n:l: flag
do
    case "${flag}" in
        v) SOLV_NAME=${OPTARG};;
        u) SOLU_NAME=${OPTARG};;
        r) RES_NAME=${OPTARG};;
        n) NUM_MOL=${OPTARG};;
        l) BOX_LEN=${OPTARG};;
    esac
done

#go into hfc_ops/general_mdp
export HOMEDIR=$PWD
echo "solvname and soluname"
echo ${SOLV_NAME} ${SOLU_NAME}
cd general_mdp
pwd
ls
perl ../write_mdp.pl min.mdp
perl ../write_mdp.pl npt.mdp
perl ../write_mdp.pl md.mdp

#go to ./hfc_opls
cd ..

# Set some environment variables 
#-----FREE_ENERGY is where the solvated boxes are
FREE_ENERGY=${HOMEDIR}/${SOLV_NAME}/${SOLU_NAME}/solvate
#-----WORKDIR is where the free energy lambda directories will be made
WORKDIR=${HOMEDIR}/${SOLV_NAME}/${SOLU_NAME}/full_test
echo "Free energy home directory set to $FREE_ENERGY"
MDP=${FREE_ENERGY}/../../../general_mdp
echo ".mdp files are stored in $MDP"

# Change to the location of your GROMACS-2018 installation
GMX=/home/pablo/repos/gromacs_tar/bin

mkdir -p ${WORKDIR}

#enter the correct WORKDIR
for (( i=0; i<41; i++ ))
do
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

    $GMX/gmx grompp -f $MDP/min_$LAMBDA.mdp -c $FREE_ENERGY/solvated.gro -p $FREE_ENERGY/solvated_top.top -o min$LAMBDA.tpr -maxwarn 1

    # # CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 13-24 $GMX/gmx mdrun -ntmpi 1 -ntomp 12 -deffnm min$LAMBDA
    # CUDA_VISIBLE_DEVICES=1 $GMX/gmx mdrun -deffnm min$LAMBDA

    # sleep 10

    # #####################
    # # NVT EQUILIBRATION #
    # #####################
    # echo "Starting constant volume equilibration..."

    cd ../
    mkdir NVT
    cd NVT

    $GMX/gmx grompp -f $MDP/nvt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -o nvt$LAMBDA.tpr

    # $GMX/gmx mdrun -deffnm nvt$LAMBDA
    CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 13-24 $GMX/gmx mdrun -ntmpi 1 -ntomp 12 -deffnm nvt$LAMBDA
    # CUDA_VISIBLE_DEVICES=1 $GMX/gmx mdrun -deffnm nvt$LAMBDA

    echo "Constant volume equilibration complete."

    sleep 10

    # #####################
    # # NPT EQUILIBRATION #
    # #####################
    # echo "Starting constant pressure equilibration..."

    # cd ../
    # mkdir NPT
    # cd NPT

    # # $GMX/gmx grompp -f $MDP/npt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -t ../EM/min$LAMBDA.cpt -o npt$LAMBDA.tpr
    # $GMX/gmx grompp -f $MDP/npt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -o npt$LAMBDA.tpr -maxwarn 1

    # # CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 13-24 $GMX/gmx mdrun -ntmpi 1 -ntomp 12 -deffnm npt$LAMBDA
    # CUDA_VISIBLE_DEVICES=1 $GMX/gmx mdrun -deffnm npt$LAMBDA

    # echo "Constant pressure equilibration complete."

    # sleep 10

    # #################
    # # PRODUCTION MD #
    # #################
    # echo "Starting production MD simulation..."

    # cd ../
    # mkdir Production_MD
    # cd Production_MD

    # $GMX/gmx grompp -f $MDP/md_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/solvated_top.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 1

    # # CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 13-24 $GMX/gmx mdrun -ntmpi 1 -ntomp 12 -deffnm md$LAMBDA
    # CUDA_VISIBLE_DEVICES=1 $GMX/gmx mdrun -deffnm md$LAMBDA

    # echo "Production MD complete."

    # # End
    # echo "-------------------------------------Ending. Job completed for lambda = $LAMBDA -------------------------------------"

    # cd $FREE_ENERGY
done
cd $HOMEDIR
exit;