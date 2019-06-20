# jsalt2019-tutorials

Speaker detection and speaker diarization tutorials for JSALT2019 summer school

## Setup (make links to dependencies)
```bash
git clone https://github.com/jsalt2019-diadet/jsalt2019-tutorial.git
cd jsalt2019-tutorial
./make_aws_links.sh
```

## Steps for speaker detection task
```bash
cd egs/sitw_tutorial/v1
./run_001_prepare_data.sh
./run_002_compute_mfcc_evad.sh
./run_010_prepare_xvec_train_data.sh
./run_011_train_xvector.sh
./run_030_extract_xvectors.sh
./run_040_eval_be.sh
```

## Steps for speaker diarization task
```bash
cd egs/callhome_diarization/v1
./run.sh
```
     
## Directory structure:
 - The directory structure of the repo looks like this:
```bash
./jsalt2019-tutorial
./jsalt2019-tutorial/tools
./jsalt2019-tutorial/tools/anaconda
./jsalt2019-tutorial/tools/anaconda/anaconda3
./jsalt2019-tutorial/tools/kaldi
./jsalt2019-tutorial/tools/kaldi/kaldi
./jsalt2019-tutorial/tools/hyperion
./jsalt2019-tutorial/tools/hyperion/hyperion
./jsalt2019-tutorial/egs
./jsalt2019-tutorial/egs/sitw_tutorial
./jsalt2019-tutorial/egs/sitw_tutorial/v1
./jsalt2019-tutorial/egs/callhome_diarization
./jsalt2019-tutorial/egs/callhome_diarization/v1
```
 - Directories:
    - tools: contains external repos and tools like kaldi, python, pyannotate, hyperion, cudnn, etc.
    - egs: contains the recipes
       - egs/sitw_tutorial: recipe for speaker detection with a subset of speakers in the wild
          - v1: Version 1 is based on kaldi x-vectors



