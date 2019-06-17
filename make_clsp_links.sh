#!/bin/bash

#This script creates links in the tools directory to
# - kaldi
# - anaconda3.5
# - cudnn
# This avoids that every person need its own copy

#kaldi
cd tools/kaldi
if [ ! -f kaldi ]; then
    ln -s /export/b15/janto/kaldi/kaldi-villalba kaldi
fi
cd -

# anaconda 3.5
cd tools/anaconda
if [ ! -f anaconda3 ];then
    ln -s /home/janto/usr/local/anaconda3.5 anaconda3.5
fi
cd -

#hyperion link
cd tools/hyperion
if [ ! -f hyperion ];then
    ln -s /export/b17/janto/hyperion/hyperion-jsalt19 hyperion
fi
cd -

#nnet model for sitw tutorial
mkdir -p egs/sitw_tutorial/v1/exp
cd egs/sitw_tutorial/v1/exp
if [ ! -f xvector_nnet_2a.1.voxceleb_div2 ];then
    ln -s /export/fs01/jsalt19/resources/embeddings_nnets/kaldi_xvec/mfcc40/xvector_nnet_2a.1.voxceleb_div2 xvector_nnet_2a.1.voxceleb_div2
fi
cd -

#nnet model for callhome tutorial
# TODO


# # cudnn
# cd tools/cudnn
# #cudnn v7.4 for cuda 9.0 needed by pytorch 1.0 (conda enviroment pytorch1.0_cuda9.0)
# if [ ! -f cudnn-9.0-v7.4 ];then
#     ln -s /home/janto/usr/local/cudnn-9.0-v7.4 cudnn-9.0-v7.4 
# fi

# #cudnn v7.1 for cuda 9.1 needed by tf1.8 (conda environment tensorflow1.8g_gpu)
# if [ ! -f cudnn-9.1-v7.1 ];then
#     ln -s /home/janto/usr/local/cudnn-9.1-v7.1 cudnn-9.1-v7.1
# fi


