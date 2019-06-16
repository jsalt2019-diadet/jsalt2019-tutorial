#!/bin/bash
# Copyright 2019 Johns Hopkins University (Jesus Villalba)  
# Apache 2.0.
#
set -e

print_header=false

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# -ne 4 ]; then
    echo "Usage: $0 <system-name> <metric-field-in-results-file> <metric-name> <sitw-score-dir>"
    exit 1;
fi

name=$1
metric_field=$2
metric_name=$3
sitw_dir=$4

declare -a header_1
declare -a header_2
declare -a conds
header_1[0]="clean"
header_2[0]=""
conds[0]=""

ii=1
for noise in noise music babble chime3bg
do
    header_1[$ii]=$noise
    for snr in 15 10 5 0 -5
    do
	header_2[$ii]=$snr
	conds[ii]=_${noise}_snr$snr
	ii=$(($ii+1))
    done
done
header_1[$ii]="reverb RT60"
for rt60 in 0.0-0.5 0.5-1.0 1.0-1.5 1.5-4.0
do
    header_2[$ii]=$rt60
    conds[ii]=_reverb_rt60-$rt60
    ii=$(($ii+1))
done

num_conds=${#conds[*]}

if [ "$print_header" == "true" ];then
    
    #print database names
    printf "System ($metric_name),SITW DEV,"
    for((i=0;i<$num_conds-1;i++)); do
	printf ","
    done
    printf "SITW EVAL,"
    for((i=0;i<$num_conds-1;i++));do
	printf ","
    done
    printf "\n"
    
    #print first header
    printf ","
    for((i=0;i<$num_conds;i++));do
    	printf "${header_1[$i]},"
    done
    for((i=0;i<$num_conds;i++));do
    	printf "${header_1[$i]},"
    done
    printf "\n"
    
    #print second header
    printf ","
    for((i=0;i<$num_conds;i++));do
    	printf -- "${header_2[$i]},"
    done
    for((i=0;i<$num_conds;i++));do
    	printf -- "${header_2[$i]},"
    done
    printf "\n"
fi


printf "$name,"

for db in dev eval
do
    for((i=0;i<$num_conds;i++))
    do
	res_file=${sitw_dir}${conds[$i]}/sitw_${db}_core-core_results
	awk -v f=$metric_field '{ printf "%.3f,", $f}' $res_file
    done
done
printf "\n"
