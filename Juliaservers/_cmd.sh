# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:42
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-08 15:03:08

#!/bin/bash
julia="/admin/home/julia/bin/julia"
user="jp_$1"
su - $user -c "$julia /admin/home/raftaar/Util/Run/server.jl $1 $2"
