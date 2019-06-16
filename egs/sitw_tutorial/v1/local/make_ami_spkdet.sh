#!/bin/bash
# Copyright
#                2019   Johns Hopkins University (Author: Jesus Villalba)
# Apache 2.0.

# Make lists for JSALT19 worshop speaker detection and tracking task
# for AMI dataset

if [  $# != 3 ]; then
    echo "$0 <wav-path> <list-path> <output_path>"
    exit 1
fi

train_mics="Mix-Headset Array1-01 Array2-01"
test_mics="Mix-Headset Array1-01 Array2-01"

wav_path=$1
list_path=$2
output_path=$3

data_name=jsalt19_spkdet_ami

# # Make Training data
# # This will be used to adapt NNet and PLDA models
# combine_str=""
# combine_vad=""
# for mic in $train_mics
# do

#     python local/make_jsalt19_spkdet.py \
# 	   --list-path $list_path/train \
# 	   --wav-path $wav_path \
# 	   --output-path $output_path \
# 	   --data-name $data_name \
# 	   --partition train \
# 	   --mic $mic \
# 	   --rttm-suffix ${mic}_train
    
    
#     awk -v suff="$mic" '{$1=$1"."suff; print $0}' $list_path/train/all.uem \
# 	> $output_path/${data_name}_train_${mic}/diarization.uem
    
#     #fix ES2010d files have 2 channels
#     awk '$1~/ES2010d/ { print $1,"sox "$2" -t wav - remix 1 |" }
#          $1!~/ES2010d/ { print $0}' \
# 	$output_path/${data_name}_train_${mic}/wav.scp \
# 	>  $output_path/${data_name}_train_${mic}/wav.scp.tmp
#     mv $output_path/${data_name}_train_${mic}/wav.scp.tmp $output_path/${data_name}_train_${mic}/wav.scp

	
#     #make spk2utt so kaldi don't complain
#     utils/utt2spk_to_spk2utt.pl $output_path/${data_name}_train_${mic}/utt2spk \
# 				> $output_path/${data_name}_train_${mic}/spk2utt

#     utils/fix_data_dir.sh $output_path/${data_name}_train_${mic}
#     combine_str="$combine_str $output_path/${data_name}_train_${mic}"
#     combine_vad="$combine_vad $output_path/${data_name}_train_${mic}/vad.rttm"
# done
# utils/combine_data.sh $output_path/${data_name}_train $combine_str
# cat $combine_vad > $output_path/${data_name}_train/vad.rttm

# Make dev data
echo "making $data_name dev"
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
echo "making $data_name eval"
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
