# @Author: Shiv Chawla
# @Date:   2017-11-17 11:04:27
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-18 15:25:56

#!/bin/bash

base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

user="$1"
user_dir="/home/$user"

#Set permissions of folder
setfacl -R -m u:$user:r-x $base_dir

setfacl -R -m u:$user:r-x $user_dir
setfacl -R -m u:$user:rwx $user_dir/local

setfacl -R -m u:$user:--x $raftaar_dir    
setfacl -R -m u:$user:--- $raftaar_dir/Util
setfacl -R -m u:$user:r-x $raftaar_dir/Run
setfacl -R -m u:$user:r-x $raftaar_dir/Benchmark
#setfacl -R -m u:$user:r-x $raftaar_dir/API

setfacl -R -m u:$user:--x $yojak_dir