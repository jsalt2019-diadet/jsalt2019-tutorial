#!/bin/bash
# Copyright
#                2018   Johns Hopkins University (Author: Jesus Villalba)
#                2017   David Snyder
#                2017   Johns Hopkins University (Author: Daniel Garcia-Romero)
#                2017   Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0.
#
. ./cmd.sh
. ./path.sh
set -e

stage=1
config_file=default_config.sh

. parse_options.sh || exit 1;
. $config_file

xvector_dir=exp/xvectors/$nnet_name

if [ $stage -le 1 ]; then
    #create subset of voxceleb with segments of more than 15secs
    utils/subset_data_dir.sh \
	--utt-list <(awk '$2>1500' data/$plda_data/utt2num_frames) \
         data/${plda_data} data/${plda_data}_15s

fi


if [ $stage -le 2 ]; then
    # Extract xvectors for training LDA/PLDA
    for name in ${plda_data}_15s
    do
	steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 12G" --nj 60 \
					     $nnet_dir data/${name} \
					     $xvector_dir/${name}
    done

fi


if [ $stage -le 3 ]; then
    # Extracts x-vectors for evaluation clean
    for name in sitw_dev_enroll sitw_dev_test sitw_eval_enroll sitw_eval_test
    do
	steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
					      $nnet_dir data/$name \
					      $xvector_dir/$name
    done

fi



if [ $stage -le 4 ]; then
    # Extracts x-vectors for evaluation noisy

    for dset in sitw_dev_test sitw_eval_test
    do
	#for noise
	for noise in noise music babble chime3bg
	do
	    for snr in 15 10 5 0 -5
	    do
		name=${dset}_${noise}_snr${snr}
		steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
						     $nnet_dir data/$name \
						     $xvector_dir/$name
	    done
	done
	#for reverb
	for rt60 in 0.0-0.5 0.5-1.0 1.0-1.5 1.5-4.0
	do
	    name=${dset}_reverb_rt60-$rt60
	    steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
						 $nnet_dir data/$name \
						 $xvector_dir/$name
	done
    done
fi


if [ $stage -le 5 ]; then
    #combine all sitw x-vectors
    rm -rf $xvector_dir/sitw_combined
    mkdir -p $xvector_dir/sitw_combined
    for d in $(ls $xvector_dir | grep sitw_)
    do
	cat $xvector_dir/$d/xvector.scp
    done > $xvector_dir/sitw_combined/xvector.scp
    #check that there is not repited lines in combined xvector
    NT=$(wc -l $xvector_dir/sitw_combined/xvector.scp | awk '{ print $1}')
    NU=$(awk '{ print $1}' $xvector_dir/sitw_combined/xvector.scp | sort -u | wc -l | awk '{ print $1}')
    if [ $NT -gt $NU ];then
	echo "There are repited lines in $xvector_dir/sitw_combined/xvector.scp"
	echo "num_lines=$NT, num_unique_lines=$NU"
	echo "something is wrong somewhere"
	exit 1
    fi
fi

exit
