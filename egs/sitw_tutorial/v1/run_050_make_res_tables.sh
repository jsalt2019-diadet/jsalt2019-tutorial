#!/bin/bash
# Copyright      2018   Johns Hopkins University (Author: Jesus Villalba)
#
# Apache 2.0.
#
. ./cmd.sh
. ./path.sh
set -e

config_file=default_config.sh

. parse_options.sh || exit 1;
. $config_file

score_dir=exp/scores/$nnet_name/${be_name}/plda
name="$nnet_name $be_name"

#print EER table
local/make_table_line_sitw_noisy.sh --print-header true "$name" 2 EER $score_dir
echo ""


#print MinDCF(0.05) table
local/make_table_line_sitw_noisy.sh --print-header true "$name" 4 "MinDCF\(0.05\)" $score_dir
echo ""

