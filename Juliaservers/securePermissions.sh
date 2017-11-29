# @Author: Shiv Chawla
# @Date:   2017-11-17 11:04:27
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-29 11:08:38

#!/bin/bash
user="$1"
base_dir="/home/$user"
if [ -z "$2" ]
  then
    echo "No base directory supplied"
    echo "Defaulting: ${base_dir}"
else
    base_dir="$2"
fi

raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

echo "Restricting"
echo "$base_dir"

#Set permissions of folder
setfacl -R -m u:$user:--x $raftaar_dir    
setfacl -R -m u:$user:--- $raftaar_dir/Util
setfacl -R -m u:$user:r-x $raftaar_dir/Run
setfacl -R -m u:$user:r-x $raftaar_dir/Benchmark

setfacl -R -m u:$user:--x $yojak_dir