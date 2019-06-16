#!/usr/bin/env python
"""
 Copyright 2019 Johns Hopkins University  (Author: Jesus Villalba)
  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)  
"""

import sys
import os
import argparse
import time
import logging
import subprocess
import re

import numpy as np
import pandas as pd

def find_audios(wav_path):

    command = 'find %s -name "*.wav"' % (wav_path)
    wavs = subprocess.check_output(command, shell=True).decode('utf-8').splitlines()
    keys = [ os.path.splitext(os.path.basename(wav))[0] for wav in wavs ]
    #remove CH1 from chime5 U0x
    keys = [re.sub(r'\.CH1$','', k) for k in keys]
    data = {'key': keys, 'file_path': wavs}
    df_wav = pd.DataFrame(data)
    return df_wav

def rttm_is_sorted_by_tbeg(rttm):
    tbeg=rttm['tbeg'].values
    file_id=rttm['file_id'].values
    return np.all(np.logical_or(tbeg[1:]-tbeg[:-1]>=0,
                                file_id[1:] != file_id[:-1]))

def sort_rttm(rttm):
    return rttm.sort_values(by=['file_id','tbeg'])


def read_rttm(list_path, sep=' ', rttm_suffix=''):

    rttm_file='%s/all%s.rttm' % (list_path, rttm_suffix)
    rttm = pd.read_csv(rttm_file, sep=sep, header=None,
                       names=['segment_type','file_id','chnl','tbeg','tdur',
                              'ortho','stype','name','conf','slat'], dtype={'name':str})
    #remove empty lines:
    index = (rttm['tdur']>= 0.025)
    rttm = rttm[index]
    rttm['ortho'] = '<NA>'
    rttm['stype'] = '<NA>'
    if not rttm_is_sorted_by_tbeg(rttm):
        print('RTTM %s not properly sorted, sorting it' % (rttm_file))
        rttm = sort_rttm(rttm)

    #cross with uem
    uem_file='%s/all%s.uem' % (list_path, rttm_suffix)
    uem = pd.read_csv(uem_file, sep=' ', header=None,
                      names=['file_id','chnl','file_tbeg','file_tend'])
    rttm_uem = pd.merge(left=rttm, right=uem, on=['file_id', 'chnl'])

    assert rttm_uem.shape[0] == rttm.shape[0]

    index_fix=(rttm_uem['tbeg'] < rttm_uem['file_tend']) & (rttm_uem['tbeg'] + rttm_uem['tdur']> rttm_uem['file_tend'])
    if np.sum(index_fix) > 0:
        print('fixing %d segments with exceding file duration' % (np.sum(index_fix)))
        print(rttm_uem[index_fix])
        rttm_uem.loc[index_fix, 'tdur'] = 0 # rttm_uem[index_fix].file_tend - rttm_uem[index_fix].tbeg
              
    index_keep=(rttm_uem['tbeg'] < rttm_uem['file_tend']) 
    n_rm = rttm.shape[0] - np.sum(index_keep)
    if n_rm > 0:
        print('removing %d segments outside file duration' % (n_rm))
        print(rttm_uem[~index_keep])
        rttm_uem = rttm_uem[index_keep]

    rttm = rttm_uem.drop(columns=['file_tbeg', 'file_tend'])
    
    return rttm



def remove_overlap_from_rttm_vad(rttm):

    tbeg_index = rttm.columns.get_indexer(['tbeg'])
    tdur_index = rttm.columns.get_indexer(['tdur'])
    tend = np.asarray(rttm['tbeg'] + rttm['tdur'])
    index = np.ones(rttm.shape[0], dtype=bool)
    p = 0
    for i in range(1, rttm.shape[0]):
        if rttm['file_id'].iloc[p] == rttm['file_id'].iloc[i]:
            if tend[p] > rttm.iloc[i, tbeg_index].item():
                index[i] = False
                if tend[i] > tend[p]:
                    tend[p] = tend[i]
                    new_dur = tend[i] - rttm.iloc[p, tbeg_index].item()
                    rttm.iloc[p, tdur_index] = new_dur
            else:
                p = i
        else:
            p = i

    rttm = rttm.loc[index]
    return rttm
            

def filter_wavs(df_wav, file_names):
    df_wav = df_wav.loc[df_wav['key'].isin(file_names)].sort_values('key')
    return df_wav


def write_wav(df_wav, output_path, bin_wav=False):

    with open(output_path + '/wav.scp', 'w') as f:
        for key,file_path in zip(df_wav['key'], df_wav['file_path']):
            if bin_wav:
                f.write('%s sox %s -t wav - remix 1 | \n' % (key, file_path))
            else:
                f.write('%s %s\n' % (key, file_path))
            


def write_dummy_utt2spk(file_names, output_path):
    
    with open(output_path + '/utt2spk', 'w') as f:
        for fn in file_names:
            f.write('%s %s\n' % (fn, fn))


def write_rttm_vad(df_vad, output_path):
    file_path = output_path + '/vad.rttm'
    df_vad[['segment_type', 'file_id', 'chnl',
            'tbeg','tdur','ortho', 'stype',
            'name', 'conf', 'slat']].to_csv(
                file_path, sep=' ', float_format='%.3f',
                index=False, header=False)


def write_rttm_spk(df_vad, output_path):
    file_path = output_path + '/diarization.rttm'
    df_vad[['segment_type', 'file_id', 'chnl',
            'tbeg','tdur','ortho', 'stype',
            'name', 'conf', 'slat']].to_csv(
                file_path, sep=' ', float_format='%.3f',
                index=False, header=False)



def write_vad_segm_fmt(rttm_vad, output_path):
    with open(output_path + '/vad.segments', 'w') as f:
        for row in rttm_vad.itertuples():
            tbeg = row.tbeg
            tend = row.tbeg + row.tdur
            segment_id = '%s-%07d-%07d' % (row.file_id, int(tbeg*100), int(tend*100))
            f.write('%s %s %.2f %.2f\n' % (segment_id, row.file_id, tbeg, tend))

    

def make_jsalt19_spkdiar(list_path, wav_path, output_path, data_name, partition, rttm_suffix, mic, wav_suffix, bin_wav):

    if mic == '':
        output_path = '%s/%s_%s' % (output_path, data_name, partition)
    else:
        output_path = '%s/%s_%s_%s' % (output_path, data_name, partition, mic)
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    print('read audios')
    df_wav = find_audios(wav_path)
    print('read rttm')
    rttm = read_rttm(list_path, rttm_suffix=rttm_suffix)

    if wav_suffix != '':
        rttm['file_id'] = rttm['file_id'].astype(str) + wav_suffix
    
    print('make wav.scp')
    file_names = rttm['file_id'].sort_values().unique()
    df_wav = filter_wavs(df_wav, file_names)
    write_wav(df_wav, output_path, bin_wav)

    print('write utt2spk')
    write_dummy_utt2spk(file_names, output_path)

    print('write diar rttm')
    write_rttm_spk(rttm, output_path)

    #create vad rttm
    print('make vad rttm')
    rttm_vad = rttm.copy()
    rttm_vad['name'] = 'speech'
    rttm_vad = remove_overlap_from_rttm_vad(rttm_vad)
    write_rttm_vad(rttm_vad, output_path)

    #write vad in segment format
    print('write vad segments')
    write_vad_segm_fmt(rttm_vad, output_path)
    

    
    

if __name__ == "__main__":

    parser=argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,                
        fromfile_prefix_chars='@',
        description='Make JSALT19 datasets for spk diarization')

    parser.add_argument('--list-path', dest='list_path', required=True)
    parser.add_argument('--wav-path', dest='wav_path', required=True)
    parser.add_argument('--output-path', dest='output_path', required=True)
    parser.add_argument('--data-name', dest='data_name', required=True)
    parser.add_argument('--partition', dest='partition', choices=['train', 'dev', 'eval'], required=True)
    parser.add_argument('--rttm-suffix', dest='rttm_suffix', default='')
    parser.add_argument('--wav-suffix', dest='wav_suffix', default='')
    parser.add_argument('--mic', dest='mic', default='')
    parser.add_argument('--bin-wav', dest='bin_wav', default=False, action='store_true')
    args=parser.parse_args()
    
    make_jsalt19_spkdiar(**vars(args))
