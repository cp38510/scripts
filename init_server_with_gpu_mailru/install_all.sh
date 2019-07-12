#!/bin/bash
# This script for install Nvidia drivers and CUDA 10.1 on Centos 7.6, relevant 12.07.2019

sudo -i

yum -y update
yum -y install pciutils
lspci | grep -i nvidia
yum -y install kernel-devel
yum -y group install "Development Tools"
yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
yum -y install epel-release
yum -y install dkms
yum -y install wget


wget http://us.download.nvidia.com/tesla/418.67/NVIDIA-Linux-x86_64-418.67.run
sh NVIDIA-Linux-x86_64-418.67.run
wget https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-rhel7-10-1-local-10.1.168-418.67-1.0-1.x86_64.rpm
sudo rpm -i cuda-repo-rhel7-10-1-local-10.1.168-418.67-1.0-1.x86_64.rpm
sudo yum -y clean all
sudo yum -y install cuda



echo "export PATH=/usr/local/cuda/bin:$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc


echo "Execute: nvidia-smi"
echo "Execute: nvcc --version"
echo "Execute: shutdown -r now"
