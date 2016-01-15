#!/bin/bash

#if [ $# -eq 0 ]
# then
#   FNAME="results.out"
#else
#   FNAME=$1    
#fi

echo "*************************************"
echo "**                                 **"
echo "**        R A L _ N L L S          **"
echo "**                                 **"
echo "*************************************"

#> data/results.out
#> data/results.out_data
cd ../cutest/sif/
> RAL_NLLS.sum
> RAL_NLLS_iter.sum
cat sif_names.txt | while read file; do
    echo " "
    echo " ~~~~~~~ $file ~~~~~~~~ "
    echo " "
    runcutest -p ral_nlls --decode $file
done

if [ $# -eq 1 ]
 then
    mv RAL_NLLS.sum ../../src/data/$1
else
    mv RAL_NLLS.sum ../../src/data/results.out
fi

cd ../../src/
