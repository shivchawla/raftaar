
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-19 12:15:02

#!/bin/bash
user="$1"
base_dir="$2"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

setfacl -R -m u:$user:r-x $raftaar_dir
setfacl -R -m u:$user:r-x $yojak_dir
