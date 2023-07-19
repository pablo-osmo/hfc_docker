#!/bin/bash

while getopts m:r:n:l: flag
do
    case "${flag}" in
        m) MOL_NAME=${OPTARG};;
        r) RES_NAME=${OPTARG};;
        n) NUM_MOL=${OPTARG};;
        l) BOX_LEN=${OPTARG};;
    esac
done

#first step is to use ligpargen with the smiles to make a .gro, .pdb, .top
cd make_boxes/${MOL_NAME}

#start by making a packmol box using the pdb from ligpargen!
mkdir -p min
cp ../../manual_minimization.mdp min/
gmx editconf -f ../data_files/${MOL_NAME}.gro -o min/${MOL_NAME}.pdb

cd min
/home/pablo/repos/packmol/packmol < ../box_maker.inp > box_maker.out
gmx editconf -f box.pdb -box ${BOX_LEN} -o box_with_bound.pdb 
pwd
cp ../../data_files/${MOL_NAME}.top solvent_box.top

#i need to chagne the last line of .top to have the correct number of topologies !!
head -n -3 solvent_box.top > tmp.txt && mv tmp.txt solvent_box.top
echo "${RES_NAME} ${NUM_MOL}" >> solvent_box.top

# #minimize this packmol box!
gmx grompp -f manual_minimization.mdp -c box_with_bound.pdb -p solvent_box.top -po emin.mdp -o emin.tpr
# echo "TRYING TO LIMIT THE CPU WOOOOOOOOOOOOOOOOO"
# CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 0-3 gmx mdrun -s emin.tpr -deffnm em
CUDA_VISIBLE_DEVICES=1 gmx mdrun -s emin.tpr -deffnm em
#pause between simulations
wait 5

#---------------------------------need to now do equilibrate
mkdir -p ../equil
cp ../../../manual_npt_rescale_equil.mdp ../equil/
cp ../../../manual_npt_equil.mdp ../equil/

cd ../equil

# #start with Parrinello-Rahman immediately after minimization
# gmx grompp -f manual_npt_equil.mdp -c ../min/em.gro -p ../min/solvent_box.top -o npt.tpr -maxwarn 1
# # CUDA_VISIBLE_DEVICES=1 gmx mdrun -s npt.tpr -deffnm npt
# CUDA_VISIBLE_DEVICES=1 taskset --cpu-list 13-24 gmx mdrun -ntomp 12 -s npt.tpr -deffnm npt

gmx grompp -f manual_npt_rescale_equil.mdp -c ../min/em.gro -p ../min/solvent_box.top -o npt_rescale.tpr -maxwarn 1
CUDA_VISIBLE_DEVICES=1 gmx mdrun -s npt_rescale.tpr -deffnm npt_rescale

#pause between simulations
wait 5

gmx grompp -f manual_npt_equil.mdp -c npt_rescale.gro -p ../min/solvent_box.top -o npt.tpr -maxwarn 1
CUDA_VISIBLE_DEVICES=1 gmx mdrun -s npt.tpr -deffnm npt

cd ../../..
echo "pwd at end of equilibrate_box"
pwd