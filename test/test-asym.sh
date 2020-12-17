#!/bin/nbash

mkdir $1;cd $1

# build L=0 power spectrum
sagpr_get_PS -f ../coords_asym.xyz -lm 0 -n 3 -l 3 -o PS0 > /dev/null

# build L=1 power spectrum
sagpr_get_PS -f ../coords_asym.xyz -lm 1 -n 3 -l 3 -o PS1 > /dev/null

# build L=2 power spectrum
sagpr_get_PS -f ../coords_asym.xyz -lm 2 -n 3 -l 3 -o PS2 > /dev/null

# build L=0 kernel
sagpr_get_kernel -z 2 -ps PS0.npy -o KER0 -s PS0_natoms.npy > /dev/null

# build L=1 kernel
sagpr_get_kernel -z 2 -ps PS1.npy -ps0 PS0.npy -o KER1 -s PS1_natoms.npy > /dev/null

# build L=2 kernel
sagpr_get_kernel -z 2 -ps PS2.npy -ps0 PS0.npy -o KER2 -s PS2_natoms.npy > /dev/null

# do cartesian regression
sagpr_train -r 2 -reg 1e-9 1e-6 1e-6 -f ../coords_asym.xyz -p alpha -sel 0 5 -w wt_cart -perat -pr -k KER0.npy KER1.npy KER2.npy | tee regression.out > /dev/null

# do spherical regression
sagpr_cart_to_sphr -f ../coords_asym.xyz -o coords.xyz -p alpha -r 2 > /dev/null
sagpr_train -r 0 -sp -reg 1e-9 -f coords.xyz -p alpha_L0 -sel 0 5 -w wt_sphr -perat -pr -k KER0.npy | tee regression_L0.out > /dev/null
sagpr_train -r 1 -sp -reg 1e-6 -f coords.xyz -p alpha_L1 -sel 0 5 -w wt_sphr -perat -pr -k KER1.npy | tee regression_L1.out > /dev/null
sagpr_train -r 2 -sp -reg 1e-6 -f coords.xyz -p alpha_L2 -sel 0 5 -w wt_sphr -perat -pr -k KER2.npy | tee regression_L2.out > /dev/null

# do cartesian prediction
python -c 'import numpy as np;k0 = np.load("KER0.npy");k1 = np.load("KER1.npy");k2 = np.load("KER2.npy");np.save("KER0_TT.npy",k0[:,:5]);np.save("KER1_TT.npy",k1[:,:5]);np.save("KER2_TT.npy",k2[:,:5])'
sagpr_prediction -w wt_cart -r 2 -k KER0_TT.npy KER1_TT.npy KER2_TT.npy -o prediction -as coords.xyz alpha > /dev/null

# do spherical prediction
sagpr_prediction -w wt_sphr -r 0 -sp -k KER0_TT.npy -o prediction > /dev/null
sagpr_prediction -w wt_sphr -r 1 -sp -k KER1_TT.npy -o prediction > /dev/null
sagpr_prediction -w wt_sphr -r 2 -sp -k KER2_TT.npy -o prediction > /dev/null

echo "CHECK DIFFERENCES IN WEIGHTS"
python -c 'import numpy as np;wC = np.load("wt_cart_1.npy",allow_pickle=True);wS = np.load("wt_sphr_1.npy",allow_pickle=True);print(100 * np.linalg.norm(wC[4]-wS[4]) / np.linalg.norm(wC[4]),"%")'
python -c 'import numpy as np;wC = np.load("wt_cart_2.npy",allow_pickle=True);wS = np.load("wt_sphr_2.npy",allow_pickle=True);print(100 * np.linalg.norm(wC[4]-wS[4]) / np.linalg.norm(wC[4]),"%")'


cd ../
