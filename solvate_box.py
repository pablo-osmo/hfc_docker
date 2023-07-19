import gro_utils
import rdkit
import pandas as pd
import os
import numpy as np

#read in input molecules
inp = pd.read_csv('input.csv', delimiter=', ', engine='python')

for solvent_inx, cur_solvent in inp[inp['solvent_or_solute'] == 'solvent'].iterrows():
    #box_len is angstroms for packmol, but nanometers for gromacs, so need to divide by 10
    # -----------the box length from packmol assumes the density is 1 g/mL, but should get the density of the 
    # #solvated box, which is the final gromacs file of the proj/hfc/make_boxes/{solvent}/equil/npt.gro
    # box_len = float(gro_utils.get_box_len_from_packmol(file_path=f"make_boxes/{cur_solvent['molname']}"))/10
    #------------round up to the nearest angstrom
    box_len = np.ceil(float(gro_utils.get_box_len_from_gro(file_path=f"make_boxes/{cur_solvent['molname']}/equil/npt.gro"))*10)/10
    for solu_inx, cur_solute in inp[inp['solvent_or_solute'] == 'solute'].iterrows():
        # command = f"./solvate_box.sh -v {cur_solvent['molname']} -u {cur_solute['molname']} -r {num_mol} "
        # command = command + f"-n {num_solv} -l {box_len}"
        command = f"./solvate_box.sh -v {cur_solvent['molname']} -u {cur_solute['molname']} "
        command = command + f"-l {box_len}"
        os.system(command)
        # v) SOLV_NAME=${OPTARG};;
        # u) SOLU_NAME=${OPTARG};;
        # r) RES_NAME=${OPTARG};;
        # n) NUM_MOL=${OPTARG};;
        # l) BOX_LEN=${OPTARG};;

        #create the itp and prm files for solvated topology
        num_solv = gro_utils.get_num_solvated_solvents(filepath=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        mixing_defaults = gro_utils.get_defaults_from_interchange_top(cur_solvent['molname'], filepath='make_boxes/data_files')
        gro_utils.get_itp_from_interchange_top(cur_solvent['molname'], filepath='make_boxes/data_files',
                                                outpath=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        gro_utils.get_prm_from_interchange_top(cur_solvent['molname'], filepath='make_boxes/data_files',
                                                outpath=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        gro_utils.get_itp_from_interchange_top(cur_solute['molname'], filepath='make_boxes/data_files',
                                                outpath=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        gro_utils.get_prm_from_interchange_top(cur_solute['molname'], filepath='make_boxes/data_files',
                                                outpath=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        gro_utils.write_solvated_top(cur_solute['molname'], cur_solvent['molname'], mixing_defaults, 
                                     num_solv, cur_solute['resname'], cur_solvent['resname'], 
                                     outfile_path=f"{cur_solvent['molname']}/{cur_solute['molname']}/solvate")
        
        # #--------------------------------------------equilibrate the solvent box--------------------------------------------
        # command = f"./equilibrate_solvate_box.sh -v {cur_solvent['molname']} -u {cur_solute['molname']} "
        # command = command + f"-l {box_len}"
        # os.system(command)
