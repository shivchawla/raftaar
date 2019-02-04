#!/bin/bash
user="$1"
env="$2"
port="$3"

juliaExec="/usr/local/julia/bin/julia"  

if id "$user" >/dev/null 2>&1; then
        echo "user exists"
else
        echo "user does not exist"
        mkdir /home/$user
	useradd $user -d /home/$user 
	#-g julia  	
	chown -R $user /home/$user
fi

cp /home/admin/$env/raftaar /home/$user/ -R --force

mkdir -p /home/$user/raftaar/tmp

chown -R $user /home/$user/raftaar
chgrp -R $user /home/$user/raftaar
chmod -R u=rx /home/$user/raftaar
chmod -R u=rwx /home/$user/raftaar/tmp

chown -R $user /home/$user/.julia
chgrp -R $user /home/$user/.julia
chmod -R u=rwx /home/$user/.julia

mkdir -p /home/$user/.julia/config && cp /home/admin/$env/raftaar/Deploy/startup.jl /home/$user/.julia/config/startup.jl --force
mkdir -p /home/$user/.julia/environments/v1.1/ && cp /home/admin/$env/raftaar/Manifest.toml /home/$user/.julia/environments/v1.1/Manifest.toml --force
mkdir -p /home/$user/.julia/environments/v1.1/ && cp /home/admin/$env/raftaar/Project.toml /home/$user/.julia/environments/v1.1/Project.toml --force

source /home/$user/raftaar/Deploy/launchForeverServer.sh \
		${user} ${port} ${env} "/home/${user}" $juliaExec 


