# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:42
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-08 15:38:59

#!/bin/bash
base_dir="/home/admin"
julia="$base_dir/julia/bin/julia"
user="jp_$1"
su - $user -c "$julia $base_dir/raftaar/Util/Run/server.jl $1 $2"
