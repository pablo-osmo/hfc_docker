import gro_utils
import rdkit
import pandas as pd
import os

#read in input molecules
inp = pd.read_csv('input.csv', delimiter=', ', engine='python')

for solvent_inx, cur_solvent in inp[inp['solvent_or_solute'] == 'solvent'].iterrows():
    for solu_inx, cur_solute in inp[inp['solvent_or_solute'] == 'solute'].iterrows():
        os.makedirs('./general_mdp', exist_ok=True)
        gro_utils.write_full_test_min(res_name=cur_solute['resname'], outfile_path='./general_mdp')
        gro_utils.write_full_test_npt(res_name=cur_solute['resname'], outfile_path='./general_mdp')
        gro_utils.write_full_test_md(res_name=cur_solute['resname'],  outfile_path='./general_mdp')
        print('beginning:', cur_solute['molname'], 'in', cur_solvent['molname'])
        # command = f"./run_lambda.sh -v {cur_solvent['molname']} -u {cur_solute['molname']} "
        command = f"./write_lambda.sh -v {cur_solvent['molname']} -u {cur_solute['molname']} "
        os.system(command)
