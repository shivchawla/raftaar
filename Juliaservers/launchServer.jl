# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 15:32:12

using WebSockets
using JSON

const base_dir = "/Users/shivkumarchawla"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

cd("$raftaar_dir/Juliaservers")

py_cmd = `python $(pwd())/testConnection.py`
relax_permissions_cmd =`bash $(pwd())/relaxPermissions.sh`
secure_permissions_cmd =`bash $(pwd())/securePermissions.sh`

function testConnection()
    println("Testing Connection")
    try
        run(py_cmd)
        run(secure_permissions_cmd)
    catch err
        println(err)
        sleep(20)
        testConnection()
    end
end

#=const base_dir="/home/admin"
const julia="$base_dir/bin/julia"=#

try 
    mkdir("$(pwd())/logs")
catch err
    println("Log directory already exists")
end

#include("resetPermissions.jl")
@spawn run(detach(`bash runSingleServer.sh jp`))

testConnection()
