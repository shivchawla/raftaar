# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 17:37:43

base_dir="/home"
julia="$base_dir/julia/bin/julia"

user="$1"
user_dir="/home/$user"

if [ ! -d "$user_dir/local" ]; then
        mkdir "$user_dir/local"
fi

chown $user $user_dir/local

echo "su - $user -c `$julia $base_dir/Juliaservers/server.jl`"
#julia /Users/shivkumarchawla/raftaar/Juliaservers/server.jl
