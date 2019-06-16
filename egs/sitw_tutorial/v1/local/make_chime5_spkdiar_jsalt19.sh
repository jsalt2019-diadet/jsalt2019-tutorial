#!/bin/bash
# Copyright
#                2019   Johns Hopkins University (Author: Jesus Villalba)
# Apache 2.0.

# Make lists for JSALT19 worshop speaker diarization
# for CHiMe5 dataset
set -e 

if [  $# != 3 ]; then
    echo "$0 <wav-path> <list-path> <output_path>"
    exit 1
fi

train_mics="PXX U01 U02 U03 U04 U05 U06"
test_mics="U01 U06"

wav_path=$1
list_path=$2
output_path=$3

data_name=jsalt19_spkdiar_chime5

# Make Training data
# This will be used to adapt NNet and PLDA models
combine_str=""
for mic in $train_mics
do
    if [ $mic == "PXX" ];then
	args="--bin-wav"
    else
	args=""
    fi
    echo "making $data_name train mic-$mic"
    python local/make_jsalt19_spkdiar.py \
	   --list-path $list_path/train \
	   --wav-path $wav_path \
	   --output-path $output_path \
	   --data-name $data_name \
	   --partition train \
	   --rttm-suffix .$mic \
	   --mic $mic $args \


    cp $list_path/train/all.$mic.uem $output_path/${data_name}_train_${mic}/diarization.uem

    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_train_${mic}/utt2spk \
				> $output_path/${data_name}_train_${mic}/spk2utt

    utils/fix_data_dir.sh $output_path/${data_name}_train_${mic}
    combine_str="$combine_str $output_path/${data_name}_train_${mic}"
done
utils/combine_data.sh $output_path/${data_name}_train $combine_str

for f in diarization.rttm diarization.uem vad.rttm vad.segments
do
    for mic in $train_mics
    do
	cat $output_path/${data_name}_train_${mic}/$f
    done > $output_path/${data_name}_train/$f
done


for mic in $test_mics
do
    # Make dev data
    echo "making $data_name dev mic-$mic"
    python local/make_jsalt19_spkdiar.py \
	   --list-path $list_path/dev \
	   --wav-path $wav_path \
	   --output-path $output_path \
	   --data-name $data_name \
	   --partition dev \
	   --rttm-suffix ${mic}_dev \
	   --mic $mic

    cp $list_path/train/all.$mic.uem $output_path/${data_name}_dev_$mic/diarization.uem
    
    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_dev_$mic/utt2spk \
				> $output_path/${data_name}_dev_$mic/spk2utt
    
    utils/fix_data_dir.sh $output_path/${data_name}_dev_$mic
done


for mic in $test_mics
do
    # Make eval data
    echo "making $data_name eval mic-$mic"
    python local/make_jsalt19_spkdiar.py \
	   --list-path $list_path/eval \
	   --wav-path $wav_path \
	   --output-path $output_path \
	   --data-name $data_name \
	   --partition eval \
	   --rttm-suffix ${mic}_test \
	   --mic $mic

    
    cp $list_path/eval/all.$mic.uem $output_path/${data_name}_eval_$mic/diarization.uem
    #make spk2utt so kaldi don't complain
    utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_eval_$mic/utt2spk \
				> $output_path/${data_name}_eval_$mic/spk2utt
    
    utils/fix_data_dir.sh $output_path/${data_name}_eval_$mic
done
