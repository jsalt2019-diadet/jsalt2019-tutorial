#!/usr/bin/env bash
linktomake=tools/kaldi/kaldi
if [ ! -L $linktomake ]; then
    ln -sv /export/fs01/skataria/kaldi $linktomake
fi

linktomake=tools/hyperion
if [ ! -L $linktomake ]; then
    ln -sv /export/fs01/skataria/hyperion $linktomake
fi

mkdir -pv egs/sitw_tutorial/v1/exp
linktomake=egs/sitw_tutorial/v1/exp/xvector_nnet_2a.1.voxceleb_div2
if [ ! -L $linktomake ]; then
    ln -sv /export/fs01/skataria/storage/xvector_nnet_2a.1.voxceleb_div2 $linktomake
fi

linktomake=tools/anaconda/anaconda3.5
if [ ! -L $linktomake ]; then
    ln -sv /home/skataria/anaconda3 $linktomake
fi
