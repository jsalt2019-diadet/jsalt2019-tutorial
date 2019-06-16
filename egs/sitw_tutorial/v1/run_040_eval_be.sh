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
			    $xvector_dir/${plda_data}_15s/xvector.scp \
			    data/${plda_data}_15s \
			    $be_dir 
fi


if [ $stage -le 2 ];then
    #eval back-end on clean data
    for subset in dev eval
    do
	(
	    name=sitw_$subset
	    steps_be/eval_be_v1.sh --cmd "$train_cmd" --plda_type $plda_type \
				   data/${name}_test/trials/core-core.lst \
				   data/${name}_enroll/utt2spk \
				   $xvector_dir/sitw_combined/xvector.scp \
				   $be_dir/lda_lnorm.h5 \
				   $be_dir/plda.h5 \
				   $score_plda_dir/${name}_core-core_scores
	    local/score_sitw_core.sh data/${name}_test $subset $score_plda_dir
	) &

    done
    wait
fi


if [ $stage -le 3 ];then
    for subset in dev eval
    do
	name=sitw_$subset
	#for noise
	for noise in noise music babble chime3bg
	do
	    for snr in 15 10 5 0 -5
	    do
		(
		    cond=${noise}_snr${snr}
		    steps_be/eval_be_v1.sh --cmd "$train_cmd" --plda_type $plda_type \
		    			   data/${name}_test_${cond}/trials/core-core.lst \
		    			   data/${name}_enroll/utt2spk \
		    			   $xvector_dir/sitw_combined/xvector.scp \
		    			   $be_dir/lda_lnorm.h5 \
		    			   $be_dir/plda.h5 \
		    			   ${score_plda_dir}_${cond}/${name}_core-core_scores
		    local/score_sitw_core.sh data/${name}_test_${cond} $subset ${score_plda_dir}_${cond}
		) &

	    done
	done
	#for reverb
	for rt60 in 0.0-0.5 0.5-1.0 1.0-1.5 1.5-4.0
	do
	    (
		cond=reverb_rt60-$rt60
	    	steps_be/eval_be_v1.sh --cmd "$train_cmd" --plda_type $plda_type \
				       data/${name}_test_${cond}/trials/core-core.lst \
				       data/${name}_enroll/utt2spk \
				       $xvector_dir/sitw_combined/xvector.scp \
				       $be_dir/lda_lnorm.h5 \
				       $be_dir/plda.h5 \
				       ${score_plda_dir}_${cond}/${name}_core-core_scores
		local/score_sitw_core.sh data/${name}_test_${cond} $subset ${score_plda_dir}_${cond}
	    ) &

	done
    done

fi

    
exit
