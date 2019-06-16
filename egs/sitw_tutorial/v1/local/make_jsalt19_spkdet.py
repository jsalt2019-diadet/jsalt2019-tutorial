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
    keys = [re.sub(r'\.CH1$','', k) for k in keys]
    data = {'key': keys, 'file_path': wavs}
    df_wav = pd.DataFrame(data)
    return df_wav


def read_enroll_lists(list_path, partition):

    if partition == 'eval':
        partition = 'test'

    list_file_bn = '%s/%s_enrollments' % (list_path, partition)
    df_enr = {}
    for dur in [5, 15, 30]:
        list_file = '%s_%d.txt' % (list_file_bn, dur)
        df_enr[dur] = pd.read_csv(list_file, sep='\t')

    return df_enr


# def read_test_list(list_path, partition):
#     if partition == 'eval':
#         partition = 'test'

#     list_file = '%s/%s_test_segments_120.txt' % (list_path, partition)
#     df_test = pd.read_csv(list_file, sep='\t')

#     return df_test


def read_trials(list_path, partition, test_length):
    
    if partition == 'eval':
        partition = 'test'

    prefix = '%s/%s_trials' % (list_path, partition)
    df_trials = {}
    df_trials_sub = {}
    for dur in [5, 15, 30]:
        trial_file = '%s_unsampled_enr_%d_test_%d.txt' % (prefix, dur, test_length)
        df_trials[dur] = pd.read_csv(trial_file, sep='\t')

        trial_file = '%s_natural_enr_%d_test_%d_N_1000.txt' % (prefix, dur, test_length)
        df_trials_sub[dur] = pd.read_csv(trial_file, sep='\t')

    return df_trials, df_trials_sub

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
                              'ortho','stype','name','conf','slat'])
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


def make_train_segments_from_rttm(df_rttm, min_dur, max_dur):

    segments = pd.DataFrame()
    #vad = pd.DataFrame()
    vad = []
    rng = np.random.RandomState(seed=1234)
    spk_ids = df_rttm['name'].sort_values().unique()
    for spk_id in spk_ids:
        print('make train segments for spk=%s' % (spk_id))
        index = df_rttm['name'] == spk_id
        df_rttm_i = df_rttm[index]
        file_names = df_rttm_i['file_id'].sort_values().unique()
        for file_name in file_names:
            print('\tmake train segments for spk=%s file_name=%s' % (spk_id, file_name))
            index = df_rttm_i['file_id'] == file_name
            df_rttm_ij = df_rttm_i[index]
            cum_length = np.cumsum(np.asarray(df_rttm_ij['tdur']))
            total_length = cum_length[-1]
            first_utt = 0
            count = 0
            while ( total_length > min_dur ):
                # select number of utterances for this segment
                cur_dur = min(rng.randint(min_dur, max_dur), total_length)
                # print('\t\t extract segment %d of length %.2f, remaining length %.2f' % (count, cur_dur, total_length-cur_dur))
                last_utt = np.where(cum_length>=cur_dur)[0][0]
                tbeg = df_rttm_ij.iloc[first_utt].tbeg-1
                tbeg = tbeg if tbeg > 0 else 0
                tend = (df_rttm_ij.iloc[last_utt].tbeg +
                        df_rttm_ij.iloc[last_utt].tdur)

                #make segment
                segment_id = '%s-%s-%07d-%07d' % (
                    spk_id, file_name, int(tbeg*100), int(tend*100))
                row = {'segment_id': segment_id, 'filename': file_name, 'speaker': spk_id,
                       'beginning_time': tbeg, 'end_time': tend }
                segments = segments.append(row, ignore_index=True)

                #make vad
                df_vad = df_rttm_ij.iloc[first_utt:last_utt+1].copy()
                df_vad['file_id'] = segment_id
                df_vad['name'] = 'speech'
                df_vad['tbeg'] = df_vad['tbeg'] - tbeg
                vad.append(df_vad)
                #vad = pd.concat([vad, df_vad], ignore_index=True)

                #update remaining length for current speaker in current audio
                cum_length -= cum_length[last_utt]
                total_length = cum_length[-1]
                first_utt = last_utt + 1
                count += 1
        

    vad = pd.concat(vad, ignore_index=True)
    segments.sort_values('segment_id', inplace=True)
    vad.sort_values(['file_id', 'tbeg'], inplace=True)

    return segments, vad
        

def enr_to_segm(df):

    df_vad = df.copy()
    df_vad.rename(columns={'onset': 'beginning_time', 'offset': 'end_time'}, inplace=True)
    df_vad['segment_id'] = ''
    df_vad.head()
    df_seg = df[['speaker', 'model_number','filename']].drop_duplicates()
    tbeg = []
    tend = []
    segment_ids = []
    for i,row in enumerate(df_seg.itertuples()):
        # find the tbeg and tend of the segment and create segment name
        mask = (df['speaker'] == row.speaker) & (
            df['model_number']== row.model_number) & (
                df['filename'] == row.filename)
        df_i = df[mask]
        tbeg_i = min(df_i['onset']) - 1 # we give and extra second at the beginning
        tbeg_i = tbeg_i if tbeg_i>0 else 0
        tend_i = max(df_i['offset']) # we don't give extra second here because we don't know the total length of the file.
        tbeg.append(tbeg_i)
        tend.append(tend_i)
        segment_id_i = '%s-%s-%07d-%07d' % (
            row.speaker, row.filename, int(tbeg_i*100), int(tend_i*100))

        if i%100==0:
            print('\tsegment %d/%d %s' % (i,df_seg.shape[0],segment_id_i))

        segment_ids.append(segment_id_i)
        
        # create groud truth vad for the segment
        mask = (df_vad['speaker'] == row.speaker) & (
            df_vad['model_number']== row.model_number) & (
                df_vad['filename'] == row.filename)
        df_vad.loc[mask, 'segment_id'] = segment_id_i
        df_vad.loc[mask, 'beginning_time'] -= tbeg_i
        df_vad.loc[mask, 'end_time'] -= tbeg_i

    df_vad['name'] = 'speech'
    df_seg['beginning_time'] = tbeg
    df_seg['end_time'] = tend
    df_seg['segment_id'] = segment_ids

    df_seg = df_seg.sort_values(by=['segment_id'])
    df_vad = df_vad.sort_values(by=['segment_id', 'beginning_time'])
    return df_seg, df_vad



def segm_vad_to_rttm_vad(segments):

    file_id = segments.segment_id
    tbeg = segments.beginning_time
    tdur = segments.end_time - segments.beginning_time
    num_segments = len(file_id)
    segment_type = ['SPEAKER'] * num_segments

    nans = ['<NA>' for i in range(num_segments)]
    chnl = [1 for i in range(num_segments)]
    ortho = nans
    stype = nans
    name = segments.speaker
    conf = [1 for i in range(num_segments)]
    slat = nans

    df = pd.DataFrame({'segment_type': segment_type,
                       'file_id': file_id,
                       'chnl': chnl,
                       'tbeg': tbeg,
                       'tdur': tdur,
                       'ortho': ortho,
                       'stype': stype,
                       'name': name,
                       'conf': conf,
                       'slat': slat})
    df['name'] = 'speech'
    return df



def trials_to_segm(df_trials):

    #merge all segments
    #segm_merged = pd.DataFrame()
    segm_merged = []
    for d in [5, 15, 30]:
        segm_d = df_trials[d][['filename','beginning_time','end_time']].drop_duplicates()
        #segm_merged = pd.concat([segm_merged, segm_d], ignore_index=True)
        segm_merged.append(segm_d)
        
    segm_merged = pd.concat(segm_merged, ignore_index=True)
    segm_merged = segm_merged.drop_duplicates()
    segment_id = ['%s-%07d-%07d' % (fn,int(tbeg*100),int(tend*100))
                  for fn,tbeg,tend in zip(
                          segm_merged['filename'],
                          segm_merged['beginning_time'],
                          segm_merged['end_time'])]
    segm_merged['segment_id'] = segment_id
    segm_merged = segm_merged.sort_values(by=['segment_id'])
    
    return segm_merged


    

# def df_trials_to_df_segm_for_train(df):

#     #merge oll trials
#     df_trials = pd.concat(list(df), ignore_index=True) 
#     mask = (df['duration_total_speech'] >= 30) #just pick segments with more than 30secs
#     df_trials = df_trials[mask]
#     df_seg = df_trials[['speaker', 'filename', 'beginning_time' ,'end_time']].drop_duplicates()
#     seg_name = []
#     for i,row in df_seg.iterrows():
#         seg_name.append('%s-%s-%07d-%07d' % (
#             row['speaker'], row['filename'],
#             int(row['beginning_time']*100), int(row['end_time']*100)))

#     df_seg['seg_name'] = seg_name
    
def make_test_rttm_diar(rttm, segm):

    rttm_test = []
    tbeg = rttm['tbeg']
    tend = rttm['tbeg'] + rttm['tdur']
    index_tbeg=rttm.columns.get_indexer(['tbeg'])
    index_tdur=rttm.columns.get_indexer(['tdur'])
    for row in segm.itertuples():
        tbeg_i = row.beginning_time
        tend_i = row.end_time
        # select rttm lines corresponding to segment i
        mask = (rttm['file_id'] == row.filename) & (
            (tbeg >= tbeg_i) | ((tbeg < tbeg_i) & (tend > tbeg_i))) & (
            (tend <= tend_i) | ((tend > tend_i) & (tbeg < tend_i)))

        rttm_i = rttm[mask].copy()
        if rttm_i.empty:
            print('segment empty %s' % row.segment_id)
            continue

        # change filename by segment_id
        rttm_i['file_id'] = row.segment_id
        #fix rttm lines that are not completely in the segment
        if rttm_i.iloc[0, index_tbeg].item() < tbeg_i:
            rttm_i.iloc[0, index_tbeg] = tbeg_i
            
        if rttm_i.iloc[-1, index_tbeg].item() + rttm_i.iloc[-1, index_tdur].item() > tend_i:
            rttm_i.iloc[-1, index_tdur] = tend_i - rttm_i.iloc[-1, index_tbeg].item()

        #align tbeg with the beginning of the segment
        rttm_i['tbeg'] -= tbeg_i

        #append to global rttms
        rttm_test.append(rttm_i)
        #rttm_test = pd.concat([rttm_test, rttm_i], ignore_index=True)

    rttm_test = pd.concat(rttm_test, ignore_index=True)
    return rttm_test


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


            
def write_utt2spk_from_segm(df_seg, output_path):

    with open(output_path + '/utt2spk', 'w') as f:
        for u,s in zip(df_seg['segment_id'], df_seg['speaker']):
            f.write('%s %s\n' % (u, s))


def write_utt2model_from_segm(df_seg, output_path):

    with open(output_path + '/utt2model', 'w') as f:
        for u,s,m in zip(df_seg['segment_id'], df_seg['speaker'], df_seg['model_number']):
            f.write('%s %s-%d\n' % (u, s, m))


def write_dummy_utt2spk(file_names, output_path):
    
    with open(output_path + '/utt2spk', 'w') as f:
        for fn in file_names:
            f.write('%s %s\n' % (fn, fn))


def write_segments(df_seg, output_path):

    with open(output_path + '/segments', 'w') as f:
        for i, row in df_seg.iterrows():
            f.write('%s %s %.2f %.2f\n' % (
                row['segment_id'], row['filename'],
                row['beginning_time'], row['end_time']))


            
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


def write_key(trials, file_path):

    with open(file_path, 'w') as f:
        for row in trials.itertuples():
            model = '%s-%d' % (row.target_speaker, row.enrollment_number)
            segm = '%s-%07d-%07d' % (row.filename, int(row.beginning_time*100), int(row.end_time*100))
            t = 'target' if row.duration_total_speech>0 else 'nontarget'
            f.write('%s %s %s\n' % (model, segm, t))
    

def make_train(df_wav, df_rttm, output_path, data_name, min_dur, max_dur, mic, bin_wav):

    if mic == '':
        output_path = '%s/%s_train' % (output_path, data_name)
    else:
        output_path = '%s/%s_train_%s' % (output_path, data_name, mic)
    
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # create wav.scp
    print('make wav.scp')
    file_names = df_rttm['file_id'].sort_values().unique()
    df_wav = filter_wavs(df_wav, file_names)
    write_wav(df_wav, output_path, bin_wav)

    #make train segments and vad
    print('make training segments')
    segments, vad = make_train_segments_from_rttm(df_rttm, min_dur, max_dur)
    print('write utt2spk')
    write_utt2spk_from_segm(segments, output_path)
    print('write segments')
    write_segments(segments, output_path)
    print('write vad in rttm format')
    write_rttm_vad(vad, output_path)
    
    
    
    
def make_deveval(df_wav, df_enr, df_trials, df_trials_sub, rttm, output_path, data_name, partition, mic):

    # enroll
    for dur in [5, 15, 30]:
        print('make enrollment dir for duration=%d' % (dur))
        # create directories
        enr_path = '%s/%s_%s_enr%d' % (output_path, data_name, partition, dur)
        if not os.path.exists(enr_path):
            os.makedirs(enr_path)

        df_enr_d = df_enr[dur]
        #create wav.scp
        print('make wav.scp')
        file_names = df_enr_d['filename'].sort_values().unique()
        df_wav_d = filter_wavs(df_wav, file_names)
        write_wav(df_wav_d, enr_path)

        
        # create enroll segments and vad
        print('cut segments from enrollment file')
        segm_enr, vad_enr = enr_to_segm(df_enr_d)
        print('prepare vad in rttm format')
        vad_rttm_enr = segm_vad_to_rttm_vad(vad_enr)
        print('write utt2spk')
        write_utt2spk_from_segm(segm_enr, enr_path)
        print('write utt2model')
        write_utt2model_from_segm(segm_enr, enr_path)
        print('write segments')
        write_segments(segm_enr, enr_path)
        print('write vad in rttm format')
        write_rttm_vad(vad_rttm_enr, enr_path)


    # test
    print('make test dir combining trials with all durations')
    tst_path = '%s/%s_%s_test' % (output_path, data_name, partition)
    if not os.path.exists(tst_path):
        os.makedirs(tst_path)

    # get segments from trials
    print('get single segments from trials')
    segm_tst = trials_to_segm(df_trials)
    write_segments(segm_tst, tst_path)

    #write utt2spk
    print('write dummy utt2spk')
    write_dummy_utt2spk(segm_tst['segment_id'].values, tst_path)
    
    # create wav.cp
    print('make wav scp')
    file_names = segm_tst['filename'].sort_values().unique()
    df_wav_tst = filter_wavs(df_wav, file_names)
    write_wav(df_wav_tst, tst_path)

    #create spk rttm
    print('make diarization rttm')
    rttm_diar = make_test_rttm_diar(rttm, segm_tst)
    write_rttm_spk(rttm_diar, tst_path)

    #create vad rttm
    print('make vad rttm')
    rttm_vad = rttm_diar.copy()
    rttm_vad['name'] = 'speech'
    rttm_vad = remove_overlap_from_rttm_vad(rttm_vad)
    write_rttm_vad(rttm_vad, tst_path)

    # create key files
    print('make key files')
    trial_path = tst_path + '/trials'
    if not os.path.exists(trial_path):
        os.makedirs(trial_path)

    for d in [5, 15, 30]:
        write_key(df_trials[d], '%s/trials_enr%d' % (trial_path, d))
        write_key(df_trials_sub[d], '%s/trials_sub_enr%d' % (trial_path, d))


    

def make_jsalt19_spkdet(list_path, wav_path, output_path, data_name, partition, min_dur, max_dur, test_dur, rttm_suffix, wav_suffix, mic, bin_wav):

    print('read audios')
    df_wav = find_audios(wav_path)
    print('read rttm')
    rttm = read_rttm(list_path, rttm_suffix=rttm_suffix)

    if wav_suffix != '':
        rttm['file_id'] = rttm['file_id'].astype(str) + wav_suffix
    
    print('making %s data directory' % (partition))
    if partition == 'train':
        make_train(df_wav, rttm, output_path, data_name, min_dur, max_dur, mic, bin_wav)
    else:
        print('read enr list')
        df_enr = read_enroll_lists(list_path, partition)
        print('read trials')
        df_trials, df_trials_sub = read_trials(list_path, partition, test_dur)
        make_deveval(df_wav, df_enr, df_trials, df_trials_sub, rttm, output_path, data_name, partition, mic)
    
    

if __name__ == "__main__":

    parser=argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,                
        fromfile_prefix_chars='@',
        description='Make JSALT19 datasets for spkdet and tracking')

    parser.add_argument('--list-path', dest='list_path', required=True)
    parser.add_argument('--wav-path', dest='wav_path', required=True)
    parser.add_argument('--output-path', dest='output_path', required=True)
    parser.add_argument('--data-name', dest='data_name', required=True)
    parser.add_argument('--partition', dest='partition', choices=['train', 'dev', 'eval'], required=True)
    parser.add_argument('--min-train-dur', dest='min_dur', default=15, type=float)
    parser.add_argument('--max-train-dur', dest='max_dur', default=60, type=float)
    parser.add_argument('--test-dur', dest='test_dur', default=60, type=int)
    parser.add_argument('--rttm-suffix', dest='rttm_suffix', default='')
    parser.add_argument('--wav-suffix', dest='wav_suffix', default='')
    parser.add_argument('--mic', dest='mic', default='')
    parser.add_argument('--bin-wav', dest='bin_wav', default=False, action='store_true')

    args=parser.parse_args()
    
    make_jsalt19_spkdet(**vars(args))
