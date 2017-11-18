
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-18 13:02:08

#!/bin/bash

base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

user="$1"

setfacl -R -m u:$user:r-x $raftaar_dir
setfacl -R -m u:$user:r-x $yojak_dir
