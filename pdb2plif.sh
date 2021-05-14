#!/bin/sh

if [ -z  "$1" ];
then
echo "Ligand file name as the 1st variable was not provided"
echo "Ligand file name could be obtained by pilot running SPORES --mode splitpdb"
echo "Usage: ./pdb2plif.sh [pdb file name] [ligand file name]"
echo "Example: ./pdb2plif.sh 4H3X.pdb ligand_10B306_0.mol2"
else

# Edit the variables below according to your settings
PLANTS=~/programs/PLANTS1.2_64bit
SPORES=~/programs/SPORES_64bit
hippos=~/.hippos/hippos.py

# Normally no change required below this point
cp $2 ligand.mol2
$SPORES --mode splitpdb $1
$PLANTS --mode bind ligand.mol2 5 protein.mol2
echo "scoring_function chemplp" > plantsconfig
echo "search_speed speed4" >> plantsconfig
echo "protein_file protein.mol2" >> plantsconfig
echo "ligand_file ligand.mol2" >> plantsconfig
echo "output_dir results" >> plantsconfig
echo "write_multi_mol2 0" >> plantsconfig
cat bindingsite.def >> plantsconfig
$PLANTS --mode rescore plantsconfig
tricky="`head -2 ligand.mol2 | tail -1`_entry_00001_conf_01"
cp ligand.mol2 results/$tricky.mol2
touch results/$tricky\_protein.mol2
echo "docking_method plants" > config.hippos
echo "docking_conf plantsconfig" >> config.hippos
echo "output_mode full full_nobb" >> config.hippos
echo "full_outfile plif_full.txt" >> config.hippos
echo "full_nobb_outfile plif_nobb.txt" >> config.hippos
echo "logfile hippos.log" >> config.hippos
echo "residue_number `grep CA PLANTSactiveSiteResidues.mol2 | grep BACKBONE | awk '{print $7}' | paste -s -d" "`" >> config.hippos
echo "residue_name `grep CA PLANTSactiveSiteResidues.mol2 | grep BACKBONE | awk '{print $8}' | paste -s -d" "`" >> config.hippos
$hippos config.hippos
fi
