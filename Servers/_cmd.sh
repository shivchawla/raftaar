# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:42
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-04 12:27:26

#!/bin/bash
julia="/root/julia/bin/julia"
user="jp_$1"
su - $user -c "$julia /root/aimsquant/raftaar/Util/server.jl $1 0.0.0.0"
