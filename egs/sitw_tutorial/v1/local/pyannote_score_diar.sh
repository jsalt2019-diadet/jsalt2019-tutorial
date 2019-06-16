#!/bin/bash
# Copyright 2019 Johns Hopkins University (Jesus Villalba)  
# Apache 2.0.
#
if [ $# -ne 3 ]; then
  echo "Usage: $0 <dataset> <dev/eval> <score-dir>"
  exit 1;
fi

export PYANNOTE_DATABASE_CONFIG=/export/fs01/jsalt19/databases/database.yml

dataset=$1
dev_eval=$2
score_dir=$3

if [ "$dev_eval" == "dev" ];then
    subset=development
else
    subset=evaluation
fi

if [[ "$dataset" =~ .*babytrain.* ]];then
    task=BabyTrain.SpeakerDiarization.All 
elif [[ "$dataset" =~ .*chime5.*U01.* ]];then
    task=CHiME5.SpeakerDiarization.U01
elif [[ "$dataset" =~ .*chime5.*U06.* ]];then
    task=CHiME5.SpeakerDiarization.U06
elif [[ "$dataset" =~ .*ami.*Mix.* ]];then
    task=AMI.SpeakerDiarization.MixHeadset
elif [[ "$dataset" =~ .*ami.*Array1.* ]];then
    task=AMI.SpeakerDiarization.Array1
elif [[ "$dataset" =~ .*ami.*Array2.* ]];then
    task=AMI.SpeakerDiarization.Array2
else
    echo "diarization task not found for dataset $dataset in database file"
    exit
fi

pyannote-metrics.py diarization --subset=development $task $score_dir/rttm \
		    2> $score_dir/pyannote.log \
		    > $score_dir/result.pyannote


