# @Author: Shiv Chawla
# @Date:   2017-10-04 12:19:26
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-04 12:23:03
#!/bin/bash
julia='/root/julia/bin/julia'
PATH=:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/julia/bin/
dir="/root/aimsquant/raftaar/Servers"
cd $dir

if [ ! -d "$PWD/logs/" ]; then
        mkdir "$PWD/logs"
fi

ports="6001 6002 6003 6004 7001"
IFS=' ' read -a portsArray <<<"$ports"
#read -a portsArray <<<$ports

for index in "${!portsArray[@]}"
do
   # do whatever on $index
   port=${portsArray[$index]}

   now="$(date +'%d%m%Y')"
   fname="$PWD/logs/JuliaServer_${port}_${now}.txt"
   efname="$PWD/logs/JuliaServer_${port}_${now}.err"
   touch $fname
   touch $efname

   user="jp_${port}"
   servicename="JuliaCC_$port"

   bash $PWD/_daemon.sh $fname $efname $servicename $port &
done