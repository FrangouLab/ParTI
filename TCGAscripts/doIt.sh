#!/bin/bash

clinicalFile=`ls ./TCGA_*_exp_*/clinical_data`
expFile=`ls ./TCGA_*_exp_*/genomicMatrix`
mutFile=`ls ./TCGA_*_mutation*/genomicMatrix`
copFile=`ls ./TCGA_*_gistic2thd*/genomicMatrix`

./expMatrix2tsv.pl -e $expFile -g geneListExp.list -t expMatrix.tsv -verbose
cut -f 1 expMatrix.tsv > patientIDs.list
cut -f 2- expMatrix.tsv | tab2csv.pl | sed -e 's/"//g' > expMatrix.csv

./expMatrix2tsv.pl -e $mutFile -g geneListMut.list -t mutMatrix.tsv -verbose
( echo -n -e 'sampleID\t'; cat geneListMut.list | tr '\n' '\t'; echo -n -e '\n'; cat mutMatrix.tsv ) > tmp.tsv
mv tmp.tsv mutMatrix.tsv

./expMatrix2tsv.pl -e $copFile -g geneListCop.list -t copMatrix.tsv -verbose
( echo -n -e 'sampleID\t'; cat geneListCop.list | tr '\n' '\t'; echo -n -e '\n'; cat copMatrix.tsv ) > tmp.tsv
mv tmp.tsv copMatrix.tsv



# Reorder mutations and clinical data
( echo sampleID; cat patientIDs.list ) > tmp.list

### Somatic mutations
# nMutations=`wc -l $mutFile | sed -e 's/ .*$//g'`
# fieldSel=\'3-`echo $nMutations + 1 | bc`\'

# nMutations=`head -1 mutMatrix.tsv | tr '\t' '\n' | wc -l`
# fieldSel=\'3-$nMutations\'
# leftJoin.pl tmp.list mutMatrix.tsv 1 1 $fieldSel NaN > mutMatrix_reOrdered.tsv
# tail -n +2 mutMatrix_reOrdered.tsv | sed -e 's/\t/,/g' > mutMatrix_reOrdered_justData.csv
# head -n 1 mutMatrix_reOrdered.tsv | sed -e 's/\t/\n/g' > mutMatrix_reOrdered_geneNames.list

nMutations=`head -1 mutMatrix.tsv | tr '\t' '\n' | wc -l`
fieldSel=\'2-$nMutations\'
leftJoin.pl tmp.list mutMatrix.tsv 1 1 $fieldSel NaN > mutMatrix_reOrdered.tsv
./booleanizeDiscMatrix.pl -in mutMatrix_reOrdered.tsv -v 1 -f 1 -g 0 -r -verbose -o mutMatrix_reOrdered_booleanized.tsv
tail -n +2 mutMatrix_reOrdered_booleanized.tsv | cut -f 2- | sed -e 's/\t/,/g' > mutMatrix_reOrdered_booleanized_justData.csv
head -n 1 mutMatrix_reOrdered_booleanized.tsv | cut -f 2- | sed -e 's/\t/\n/g' > mutMatrix_reOrdered_booleanized_geneNames.list


### Copy number alterations
# nCopies=`wc -l $copFile | sed -e 's/ .*$//g'`
# fieldSel=\'3-`echo $nCopies + 1 | bc`\'

# nCopies=`head -1 copMatrix.tsv | tr '\t' '\n' | wc -l`
# fieldSel=\'3-$nCopies\'
# leftJoin.pl tmp.list copMatrix.tsv 1 1 $fieldSel NaN > copMatrix_reOrdered.tsv
# tail -n +2 copMatrix_reOrdered.tsv | sed -e 's/\t/,/g' > copMatrix_reOrdered_justData.csv
# head -n 1 copMatrix_reOrdered.tsv | sed -e 's/\t/\n/g' > copMatrix_reOrdered_geneNames.list

nCopies=`head -1 copMatrix.tsv | tr '\t' '\n' | wc -l`
fieldSel=\'2-$nCopies\'
leftJoin.pl tmp.list copMatrix.tsv 1 1 $fieldSel NaN > copMatrix_reOrdered.tsv
./booleanizeDiscMatrix.pl -in copMatrix_reOrdered.tsv -e 10 -verbose -o copMatrix_reOrdered_booleanized.tsv
tail -n +2 copMatrix_reOrdered_booleanized.tsv | cut -f 2- | sed -e 's/\t/,/g' > copMatrix_reOrdered_booleanized_justData.csv
head -n 1 copMatrix_reOrdered_booleanized.tsv | cut -f 2- | sed -e 's/\t/\n/g' > copMatrix_reOrdered_booleanized_geneNames.list

# Clinical data
nClinical=`head -1 $clinicalFile | sed -e 's/[^\t]//g' | wc -c`
fieldSel=\'3-`echo $nClinical + 1 | bc`\'
./add1missingField.pl < $clinicalFile > tmp2.tsv
leftJoin.pl tmp.list tmp2.tsv 1 1 $fieldSel NaN > clinicalData_reOrdered.tsv

libreoffice --calc clinicalData_reOrdered.tsv

echo "We just opened 'clinicalData_reOrdered.tsv' for you. Save discrete features as 'discreteClinicalData_reOrdered.tsv', and the *names* of continuous features as 'continuousFeatures.list'. Then press [ENTER]."
read

./extractContinuousFeatures.pl
tail -n +2 continuousClinicalData_reOrdered.tsv | sed -e 's/\t/,/g' > continuousClinicalData_reOrdered_justData.csv
head -n 1 continuousClinicalData_reOrdered.tsv | sed -e 's/\t/\n/g' > continuousClinicalData_reOrdered_featNames.list


echo "Done. Ready to process dataset in matlab"