#!/bin/bash
# Copyright
#                2019   Johns Hopkins University (Author: Jesus Villalba)
# Apache 2.0.

# Make lists for JSALT19 worshop speaker detection and tracking task
# for Babytrain dataset
set -e 

if [  $# != 3 ]; then
    echo "$0 <wav-path> <list-path> <output_path>"
    exit 1
fi

wav_path=$1
list_path=$2
output_path=$3

data_name=jsalt19_spkdet_babytrain

# Make Training data
# This will be used to adapt NNet and PLDA models
# echo "making $data_name train"
# python local/make_jsalt19_spkdet.py \
#        --list-path $list_path/train \
#        --wav-path $wav_path \
#        --output-path $output_path \
#        --data-name $data_name \
#        --rttm-suffix _train \
#        --partition train

# #make spk2utt so kaldi don't complain
# utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_train/utt2spk \
# 			    > $output_path/${data_name}_train/spk2utt

# utils/fix_data_dir.sh $output_path/${data_name}_train

# Make dev data
echo "making $data_name dev"
python local/make_jsalt19_spkdet.py \
       --list-path $list_path/dev \
       --wav-path $wav_path \
       --output-path $output_path \
       --data-name $data_name \
       --partition dev \
       --rttm-suffix _dev \
       --test-dur 60


for d in 5 15 30
do
    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_dev_enr$d/utt2spk \
				> $output_path/${data_name}_dev_enr$d/spk2utt
    
    utils/fix_data_dir.sh $output_path/${data_name}_dev_enr$d
done
cp $output_path/${data_name}_dev_test/utt2spk $output_path/${data_name}_dev_test/spk2utt
utils/fix_data_dir.sh $output_path/${data_name}_dev_test

# Make eval data
echo "making $data_name eval"
python local/make_jsalt19_spkdet.py \
       --list-path $list_path/eval \
       --wav-path $wav_path \
       --output-path $output_path \
       --data-name $data_name \
       --partition eval \
       --rttm-suffix _test \
       --test-dur 60


for d in 5 15 30
do
    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_eval_enr$d/utt2spk \
				> $output_path/${data_name}_eval_enr$d/spk2utt
    
    utils/fix_data_dir.sh $output_path/${data_name}_eval_enr$d
done
cp $output_path/${data_name}_eval_test/utt2spk $output_path/${data_name}_eval_test/spk2utt
utils/fix_data_dir.sh $output_path/${data_name}_eval_test
