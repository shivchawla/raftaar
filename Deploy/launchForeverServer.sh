#!/bin/bash
user="$1"
port="$2"
env="$3" 

base_dir="/home/$user"
#base_dir="/Users/shivkumarchawla" 

if [ -z "$4" ]
  then
    echo "No base directory supplied"
    echo "Defaulting: ${base_dir}"
else
    base_dir="$4"
fi

julia="/usr/local/julia/bin/julia"
#julia="/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia"

if [ -z "$5" ]
  then
    echo "No Julia executable supplied"
    echo "Defaulting: ${julia}"
else
    julia="$5"
fi

raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"


bash $base_dir/raftaar/Juliaservers/relaxPermissions.sh $user $base_dir
su - $user -c "$julia $base_dir/raftaar/Juliaservers/forever.jl $port $env 1>&2"
