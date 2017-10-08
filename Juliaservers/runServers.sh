# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:26
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-08 15:31:13
#!/bin/bash
base_dir="/home/admin"
julia='$base_dir/bin/julia'
PATH=:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/julia/bin/

raftaar_dir="$base_dir/raftaar"
cd "$raftaar_dir/Juliaservers"

if [ ! -d "$PWD/logs/" ]; then
        mkdir "$PWD/logs"
fi

#Set permissions of folder
setfacl -R -m g:julia:r-x $raftaar_dir
setfacl -R -m g:julia:--x $raftaar_dir/Juliaservers
setfacl -R -m g:julia:r-x $raftaar_dir/Util

address="0.0.0.0"
ports="6001 6002 6003 6004 7001"
IFS=' ' read -a portsArray <<<"$ports"

for index in "${!portsArray[@]}"
do
   # do whatever on $index
   port=${portsArray[$index]}
   user="jp_${port}"
   servicename="JuliaCC_$port"

   if [ ! -d "/home/$user/local" ]; then
        mkdir "/home/$user/local"
        setfacl -R -m u:$user:r-x "/home/$user"
        setfacl -R -m u:$user:rwx "/home/$user/local"
   fi

   now="$(date +'%d%m%Y')"
   fname="$PWD/logs/JuliaServer_${port}_${now}.txt"
   efname="$PWD/logs/JuliaServer_${port}_${now}.err"
   touch $fname
   touch $efname

   bash $PWD/_daemon.sh $fname $efname $servicename $port $address &     
done

#Sleep before resetting some file permissions
sleep 200

setfacl -R -m g:julia:--- $raftaar_dir/Util
setfacl -m g:julia:r-x $raftaar_dir/Util
setfacl -R -m g:julia:r-x $raftaar_dir/Util/Run

