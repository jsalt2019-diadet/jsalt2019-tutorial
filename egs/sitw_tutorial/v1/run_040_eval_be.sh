#!/bin/bash
# Copyright       2018   Johns Hopkins University (Author: Jesus Villalba)
#                
# Apache 2.0.
#
. ./cmd.sh
. ./path.sh
set -e

stage=1
config_file=default_config.sh

. parse_options.sh || exit 1;
. $config_file
. datapath.sh 

xvector_dir=exp/xvectors/$nnet_name
be_dir=exp/be/$nnet_name/$be_name
score_dir=exp/scores/$nnet_name/${be_name}
score_plda_dir=$score_dir/plda

if [ $stage -le 1 ]; then
    #train back-end
    steps_be/train_be_v1.sh --cmd "$train_cmd" \
			    --lda_dim $lda_dim \
			    --plda_type $plda_type \
			    --y_dim $plda_y_dim --z_dim $plda_z_dim \
			    $xvector_dir/${plda_data}/xvector.scp \
			    data/${plda_data} \
			    $be_dir 
fi


if [ $stage -le 2 ];then
    #eval back-end 
    for subset in dev
    do
	name=sitw_$subset
	steps_be/eval_be_v1.sh --cmd "$train_cmd" --plda_type $plda_type \
			       data/${name}_test/trials/core-core.lst \
			       data/${name}_enroll/utt2spk \
			       $xvector_dir/sitw_combined/xvector.scp \
			       $be_dir/lda_lnorm.h5 \
			       $be_dir/plda.h5 \
			       $score_plda_dir/${name}_core-core_scores
	local/score_sitw_core.sh data/${name}_test $subset $score_plda_dir
    done

fi


    
exit
