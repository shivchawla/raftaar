
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-18 10:48:59

#!/bin/bash

base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

setfacl -R -m u:jp:r-x $raftaar_dir
setfacl -R -m u:jp:r-x $yojak_dir
