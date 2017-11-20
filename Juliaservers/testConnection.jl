# @Author: Shiv Chawla
# @Date:   2017-11-17 18:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 16:52:52

user="jp"
host="127.0.0.1"
port=8000
base_dir="/home/jp"

try
  user = ARGS[1]  
  host = ARGS[2]
  port = parse(ARGS[3])
  base_dir = ARGS[4]
end

println(base_dir)

raftaar_dir="$base_dir/raftaar"
cd("$raftaar_dir/Juliaservers")

py_cmd = `python $(pwd())/testConnection.py $host $port`
secure_permissions_cmd =`bash $(pwd())/securePermissions.sh $user $base_dir`

function testConnection()
    println("Testing Connection at $host:$port")
    try
        run(py_cmd)
    catch err
        println(err)
        sleep(20)
        testConnection()
    end
end

testConnection()

#Update permissions
run(secure_permissions_cmd)
