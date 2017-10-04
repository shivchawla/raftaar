# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:42
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-04 17:44:49

#!/bin/bash
julia="/root/julia/bin/julia"
user="jp_$1"
su - $user -c "$julia /root/aimsquant/raftaar/Util/Run/server.jl $1 0.0.0.0"
