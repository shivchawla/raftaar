
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2019-01-30 15:20:34

#!/bin/bash
user="$1"
base_dir="$2"
raftaar_dir="$base_dir/raftaar"

setfacl -R -m u:$user:r-x $raftaar_dir
