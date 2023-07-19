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

#solvate:
#make gromacs whole again, currently in proj/hfc_opls
mkdir -p ${SOLV_NAME}/${SOLU_NAME}/solvate

gmx editconf -f make_boxes/${SOLV_NAME}/equil/npt.gro -pbc -o ${SOLV_NAME}/${SOLU_NAME}/solvate/npt_whole.gro
gmx editconf -f make_boxes/data_files/${SOLU_NAME}.gro -box ${BOX_LEN} -c -o ${SOLV_NAME}/${SOLU_NAME}/solvate/${SOLU_NAME}_centered.gro
#move into proj/hfc_opls/solvent/solute
cd ${SOLV_NAME}/${SOLU_NAME}/solvate
# gmx solvate -cp camphor_centered.gro -cs npt_whole.gro -p camphor.top -box 6.2 6.2 6.2 -o camphor_in_quinoline
gmx solvate -cp ${SOLU_NAME}_centered.gro -cs npt_whole.gro -box ${BOX_LEN} ${BOX_LEN} ${BOX_LEN} -o solvated &> solvated.out

#go back to home
cd ../../..
echo "pwd after solvate_box.sh"
pwd