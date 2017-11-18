#!/bin/bash
base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"
julia="/home/admin/julia/bin/julia"

nohup $julia $raftaar_dir/Juliaservers/testConnection.jl &

user="$1"
host="$2"
port="$3"

user_dir="/home/$user"

if [ ! -d "$user_dir/local" ]; then
        mkdir "$user_dir/local"
fi

chown $user $user_dir/local

su - $user -c `$julia $base_dir/raftaar/Juliaservers/server.jl $user $host $port 1>&2`
