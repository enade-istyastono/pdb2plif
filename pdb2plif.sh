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
$SPORES --mode splitpdb $1
cp $2 ligand.mol2
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
grep "residue_name" config.hippos | sed 's/residue_name //g' | tr " " "\n" > .tmp.res.lst
echo "hydrophobic" > .tmp.plif.txt
echo "aromatic_face-to-face" >> .tmp.plif.txt
echo "aromatic_edge-to-face" >> .tmp.plif.txt
echo "H-bond_donor" >> .tmp.plif.txt
echo "H-bond_acceptor" >> .tmp.plif.txt
echo "ionic_as_the_cation" >> .tmp.plif.txt
echo "ionic_as_the_anion" >> .tmp.plif.txt
for i in $(cat .tmp.res.lst); do for j in $(cat .tmp.plif.txt); do echo "$i $j"; done; done > .tmp.res.lst.type
for j in $(seq 1 `cat .tmp.res.lst.type | wc -l`); do awk -v j="$j" '{print substr($3,j,1)}' plif_nobb.txt; done > .tmp.nobb.human
for j in $(seq 1 `cat .tmp.res.lst.type | wc -l`); do awk -v j="$j" '{print substr($3,j,1)}' plif_full.txt; done > .tmp.full.human
paste -d, .tmp.res.lst.type .tmp.nobb.human | grep ",1" | sed "s/,1//g" > nobb.plif-h.txt
paste -d, .tmp.res.lst.type .tmp.full.human | grep ",1" | sed "s/,1//g" > full.plif-h.txt
rm .tmp.full.human .tmp.nobb.human .tmp.plif.txt .tmp.res.lst .tmp.res.lst.type
fi
