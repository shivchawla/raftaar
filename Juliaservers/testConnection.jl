# @Author: Shiv Chawla
# @Date:   2017-11-17 18:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 16:52:52

const base_dir = "/home"
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
        #run(secure_permissions_cmd)
    catch err
        println(err)
        sleep(20)
        testConnection()
    end
end

testConnection()