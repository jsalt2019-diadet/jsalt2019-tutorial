#!/bin/bash
# Copyright 2019 Johns Hopkins University (Jesus Villalba)  
# Apache 2.0.
#
if [ $# -ne 4 ]; then
  echo "Usage: $0 <data-root> <dev/eval> <enroll-duration> <score-dir>"
  exit 1;
fi

set -e

data_dir=$1
dev_eval=$2
enr_dur=$3
score_dir=$4

# keys
trials=$data_dir/trials/trials_enr$enr_dur
trials_sub=$data_dir/trials/trials_sub_enr$enr_dur
db_name=jsalt19_spkdet_ami_${dev_eval}

score_file_base=$score_dir/${db_name}_enr${enr_dur}

echo "babytrain $dev_eval enr-$enr_dur total"
python local/score_dcf.py --key-file $trials --score-file ${score_file_base}_scores --output-path ${score_file_base} &
echo "babytrain $dev_eval enr-$enr_dur subsampled"
python local/score_dcf.py --key-file $trials_sub --score-file ${score_file_base}_scores --output-path ${score_file_base}_sub  &

wait



