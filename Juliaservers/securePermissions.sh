# @Author: Shiv Chawla
# @Date:   2017-11-17 11:04:27
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-19 12:33:32

#!/bin/bash
user="$1"
user_dir="/home/$user"

base_dir="$2"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

echo "Restricting"
echo "$base_dir"

#Set permissions of folder
#setfacl -R -m u:$user:r-x $base_dir

setfacl -R -m u:$user:--x $raftaar_dir    
setfacl -R -m u:$user:--- $raftaar_dir/Util
setfacl -R -m u:$user:r-x $raftaar_dir/Run
setfacl -R -m u:$user:r-x $raftaar_dir/Benchmark
#setfacl -R -m u:$user:r-x $raftaar_dir/API

setfacl -R -m u:$user:--x $yojak_dir

#setfacl -R -m u:$user:r-x $user_dir
#setfacl -R -m u:$user:rwx $user_dir/local
