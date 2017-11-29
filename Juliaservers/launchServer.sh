#!/bin/bash
cores="$1"
user="$2"
host="$3"
port="$4"

base_dir="/home/$user"
#base_dir="/Users/shivkumarchawla" 
if [ -z "$5" ]
  then
    echo "No base directory supplied"
    echo "Defaulting: ${base_dir}"
else
    base_dir="$5"
fi

julia="/usr/local/julia/bin/julia"
#julia="/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia"

if [ -z "$6" ]
  then
    echo "No Julia executable supplied"
    echo "Defaulting: ${julia}"
else
    julia="$6"
fi

raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

nohup $julia $raftaar_dir/Juliaservers/testConnection.jl $user $host $port $base_dir &

bash $base_dir/raftaar/Juliaservers/relaxPermissions.sh $user $base_dir
su - $user -c "$julia -p $cores $base_dir/raftaar/Juliaservers/server.jl $user $host $port 1>&2"
#$julia -p $cores $base_dir/raftaar/Juliaservers/server.jl $user $host $port 1>&2