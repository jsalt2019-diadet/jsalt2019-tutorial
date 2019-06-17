#Default configuration parameters for the experiment

#xvector training 
nnet_data=voxceleb_div2
nnet_vers=2a.1
nnet_name=2a.1.voxceleb_div2
nnet_num_epochs=2
nnet_dir=exp/xvector_nnet_$nnet_name


#spkdet back-end
lda_dim=200
plda_y_dim=150
plda_z_dim=200

plda_data=voxceleb_small
plda_type=splda
plda_label=${plda_type}y${plda_y_dim}_v1

be_name=lda${lda_dim}_${plda_label}_${plda_data}

