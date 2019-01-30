cmd="$1"
channelOrKey="$2"
msg="$3"
redis-cli -a '4343#$4%3417&2&387*&*&21234@@@34000990#$232@ad$$min##$$%%^^&6%$#!@!@' \
		$cmd $channelOrKey $msg 

rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG ""
rename-command SHUTDOWN ""
rename-command BGREWRITEAOF ""
rename-command BGSAVE ""
rename-command SPOP ""
rename-command SREM ""
rename-command RENAME ""
rename-command DEBUG ""