# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:26
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-04 17:41:19
#!/bin/bash
julia='/root/julia/bin/julia'
PATH=:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/julia/bin/

dir="/root/aimsquant/raftaar/Juliaservers"
cd $dir

if [ ! -d "$PWD/logs/" ]; then
        mkdir "$PWD/logs"
fi

#Set permissions of folder
raftaarDir="/root/aimsquant/raftaar/"
setfacl -R -m g:julia:--x $raftaarDir
setfacl -R -m g:julia:--x $raftaarDir/Juliaservers
setfacl -R -m g:julia:r-x $raftaarDir/Util

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

   bash $PWD/_daemon.sh $fname $efname $servicename $port &     
done

#Sleep before resetting some file permissions
sleep 20

setfacl -R -m g:julia:--- $raftaarDir/Util
setfacl -m g:julia:r-x $raftaarDir/Util
setfacl -R -m g:julia:r-x $raftaarDir/Util/Run

