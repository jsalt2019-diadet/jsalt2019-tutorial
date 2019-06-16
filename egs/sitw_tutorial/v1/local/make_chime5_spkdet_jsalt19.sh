#!/bin/bash
# Copyright
#                2019   Johns Hopkins University (Author: Jesus Villalba)
# Apache 2.0.

# Make lists for JSALT19 worshop speaker detection and tracking task
# for Chime5 dataset
set -e 

if [  $# != 3 ]; then
    echo "$0 <wav-path> <list-path> <output_path>"
    exit 1
fi

train_mics="PXX U01 U02 U03 U04 U05 U06"

wav_path=$1
list_path=$2
output_path=$3

data_name=jsalt19_spkdet_chime5

# Make Training data
# This will be used to adapt NNet and PLDA models
combine_str=""
combine_vad=""
for mic in $train_mics
do
    if [ $mic == "PXX" ];then
	args="--bin-wav"
    else
	args=""
    fi
    echo "making $data_name train mic-$mic"

    python local/make_jsalt19_spkdet.py \
	   --list-path $list_path/train \
	   --wav-path $wav_path \
	   --output-path $output_path \
	   --data-name $data_name \
	   --partition train \
	   --rttm-suffix .$mic \
	   --mic $mic $args 

    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_train_${mic}/utt2spk \
				> $output_path/${data_name}_train_${mic}/spk2utt

    utils/fix_data_dir.sh $output_path/${data_name}_train_${mic}
    combine_str="$combine_str $output_path/${data_name}_train_${mic}"
    combine_vad="$combine_vad $output_path/${data_name}_train_${mic}/vad.rttm"
done
utils/combine_data.sh $output_path/${data_name}_train $combine_str
cat $combine_vad > $output_path/${data_name}_train/vad.rttm


exit

# Make dev data
python local/make_jsalt19_spkdet.py \
       --list-path $list_path/dev \
       --wav-path $wav_path \
       --output-path $output_path \
       --data-name $data_name \
       --partition dev \
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
python local/make_jsalt19_spkdet.py \
       --list-path $list_path/eval \
       --wav-path $wav_path \
       --output-path $output_path \
       --data-name $data_name \
       --partition eval \
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
