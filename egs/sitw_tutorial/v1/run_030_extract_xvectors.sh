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
    # Extract xvectors for training LDA/PLDA
    for name in ${plda_data}
    do
	steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 12G" --nj 60 \
					     $nnet_dir data/${name} \
					     $xvector_dir/${name}
    done

fi


if [ $stage -le 2 ]; then
    # Extracts x-vectors for evaluation clean
    for name in sitw_dev_enroll sitw_dev_test
    do
	steps_kaldi_xvec/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
					      $nnet_dir data/$name \
					      $xvector_dir/$name
    done

fi



if [ $stage -le 3 ]; then
    #combine all sitw x-vectors
    echo "combining sitw enroll and test xvectors"
    rm -rf $xvector_dir/sitw_combined
    mkdir -p $xvector_dir/sitw_combined
    cat $xvector_dir/sitw_dev_{enroll,test}/xvector.scp > $xvector_dir/sitw_combined/xvector.scp
fi

exit
