#!/bin/bash
user="$1"
host="$2"
port="$3"

base_dir="/home"
if [ -z "$4" ]
  then
    echo "No base directory supplied"
    echo "Defaulting: /home"
else
    base_dir="$4"
fi

julia="/usr/local/julia/bin/julia"
if [ -z "$5" ]
  then
    echo "No Julia executable supplied"
    echo "Defaulting: /usr/local/julia/bin/julia"
else
    julia="$5"
fi

raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

nohup $julia $raftaar_dir/Juliaservers/testConnection.jl $user $host $port $base_dir &

user_dir="/home/$user"

if [ ! -d "$user_dir/local" ]; then
        mkdir "$user_dir/local"
fi

chown $user $user_dir/local

bash $base_dir/raftaar/Juliaservers/relaxPermissions.sh $user $base_dir
su - $user -c "$julia $base_dir/raftaar/Juliaservers/server.jl $user $host $port 1>&2"
