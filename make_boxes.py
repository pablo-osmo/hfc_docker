import gro_utils
import rdkit
import pandas as pd
import os

#read in input molecules
num_mol = 750
inp = pd.read_csv('input.csv', delimiter=', ', engine='python')

for row_inx, cur_mol in inp.iterrows():
    #create single molecule data files (.gro, .top, .pdb)
    print(cur_mol['smiles'])
    gro_utils.get_openff_gro_files(cur_mol['smiles'], cur_mol['resname'], cur_mol['molname'], forcefield='openff-2.0.0.offxml', save_dir='make_boxes/data_files')
    print('IamBanana')
    if cur_mol['solvent_or_solute'] == 'solvent':
        #----------------------create an intial guess of the solvent box for the solvent molecules only----------------------
        #the solutes will be placed inside of these boxes later
        box_len = gro_utils.make_packmol(cur_mol['molname'], cur_mol['smiles'], num_mol=num_mol, save_dir_base='make_boxes')
        print('saved box len:', box_len)
        #--------------------------------------------equilibrate the solvent box--------------------------------------------
        #box_len for gromacs is in nm while it is in A for packmol, so need to divide by 10
        # command = f"./equilibrate_box.sh -m {cur_mol['molname']} -r {cur_mol['resname']} -n {num_mol} -l {float(box_len)/10} &> equilibrate_{cur_mol['molname']}.out"
        command = f"./make_boxes_equilibrate.sh -m {cur_mol['molname']} -r {cur_mol['resname']} -n {num_mol} -l {float(box_len)/10}"
        os.system(command)