
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 16:53:37

#!/bin/bash

base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

setfacl -R -m u:jp:--x $base_dir
setfacl -R -m u:jp:r-x $base_dir/julia
setfacl -R -m u:jp:r-x $base_dir/.julia

setfacl -R -m u:jp:r-x $raftaar_dir
setfacl -R -m u:jp:--x $raftaar_dir/Juliaservers
setfacl -R -m u:jp:r-x $raftaar_dir/Util
setfacl -R -m u:jp:r-x $yojak_dir
