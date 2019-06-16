#!/bin/bash
# Copyright      2019   Johns Hopkins University (Author: Jesus Villalba)
#
# Apache 2.0.
#
# Convert VAD in rttm format to segments format
set -e

min_dur=3

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [  $# != 2 ]; then
    echo "$0 [--min-dur <minimum_segment_duration>] <rttm> <data-dir>"
    exit 1
fi

rttm=$1
data_dir=$2
awk '$5>='$min_dur' { tend=$4+$5; printf "%s-%s-%07d-%07d %s %.2f %.2f %s\n",$8,$2,$4*100,tend*100,$2,$4,tend,$8 }' $rttm | sort -k1,1 > $data_dir/subsegments.tmp
awk '{ print $1,$2,$3,$4}' $data_dir/subsegments.tmp > $data_dir/subsegments
#awk '{ print $2,$2}' $data_dir/subsegments.tmp | sort -u > $data_dir/utt2spk
#utils/utt2spk_to_spk2utt.pl $data_dir/utt2spk > $data_dir/spk2utt

utils/data/subsegment_data_dir.sh $data_dir \
				  $data_dir/subsegments ${data_dir}_segmented
awk '{ print $1,$5}' $data_dir/subsegments.tmp > ${data_dir}_segmented/utt2spk
utils/utt2spk_to_spk2utt.pl ${data_dir}_segmented/utt2spk > ${data_dir}_segmented/spk2utt

rm $data_dir/subsegments.tmp
