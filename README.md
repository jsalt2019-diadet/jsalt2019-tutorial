# jsalt2019-tutorials

Speaker detection and speaker diarization tutorials for JSALT2019 summer school

## Cloning the repo

- To clone the repo execute
```bash
git clone https://github.com/jsalt2019-diadet/jsalt2019-tutorial.git
```


## Dependencies:
  - Anaconda3.5:
     - Make a link to your anaconda installation in the tools directory:
     ```bash
     cd jsalt2019-tutorial/tools/anaconda
     ln -s <your-anaconda-3.5> anaconda3.5
     ```
     - or follow instructions in jsalt2019-tutorial/tools/anaconda/full_install.sh to install anaconda from scratch
  - Kaldi speech recognition toolkit
     - Make link to an existing kaldi installation
     ```bash
     cd jsalt2019-tutorial/tools/kaldi
     ln -s <your-kaldi> kaldi
     ```
     - or follow instructions in jsalt2019-tutorial/tools/anaconda/install_kaldi.sh to install kaldi from scratch

  - CuDNN: tensorflow and pytorch will need some version of cudnn
     - Make a link to some existing cudnn version that matches the requirements of your tf or pytorch, e.g.:
     ```bash
     cd jsalt2019-tutorial/tools/cudnn
     #cudnn v7.4 for cuda 9.0 needed by pytorch 1.0 
     ln -s /home/janto/usr/local/cudnn-9.0-v7.4 cudnn-9.0-v7.4
     ```
  - Recommended: use some preinstalled versions of anaconda and kaldi in the grid to avoid each person having its own.
     - To create links to preinstalled kaldi, anaconda and cudnn, run:
     ```bash
     cd jsalt2019-tutorial/
     ./make_clsp_links.sh
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
```
 - Directories:
    - tools: contains external repos and tools like kaldi, python, pyannotate, hyperion, cudnn, etc.
    - egs: contains the recipes
       - egs/sitw_tutorial: recipe for speaker detection with a subset of speakers in the wild
          - v1: Version 1 is based on kaldi x-vectors



