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

chown -R $user /home/$user/raftaar
chgrp -R $user /home/$user/raftaar
chmod -R u=rx /home/$user/raftaar

mkdir /home/$user/.julia/config && cp /home/admin/$env/raftaar/Deploy/.juliarc.jl /home/$user/.julia/config/startup.jl --force
mkdir /home/$user/.julia/environments/v1.1/ && cp /home/admin/$env/raftaar/Manifest.toml /home/$user/.julia/environments/v1.1/Manifest.toml --force
mkdir /home/$user/.julia/environments/v1.1/ && cp /home/admin/$env/raftaar/Project.toml /home/$user/.julia/environments/v1.1/Project.toml --force

# chown -R $user /home/$user/.juliarc.jl
# chgrp -R $user /home/$user/.juliarc.jl

# #sudo su - $user -c "${juliaExec} ~/raftaar/Deploy/setupUser.jl $user $env"

# #Update the Redis from local folder
# #cp -r /home/admin/$env/raftaar/Deploy/Redis-src/* /home/$user/.julia/v0.6/Redis/src/

source /home/$user/raftaar/Juliaservers/launchForeverServer.sh \
		${user} ${port} ${env} "/home/${user}" $juliaExec 



