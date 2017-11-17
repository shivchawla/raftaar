# @Author: Shiv Chawla
# @Date:   2017-11-17 11:04:27
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 16:53:46

#!/bin/bash

base_dir="/home"
raftaar_dir="$base_dir/raftaar"
yojak_dir="$base_dir/yojak"

#Set permissions of folder
setfacl -R -m u:jp:--x $raftaar_dir    
setfacl -R -m u:jp:--- $raftaar_dir/Util
setfacl -m u:jp:r-x $raftaar_dir/Util
setfacl -R -m u:jp:r-x $raftaar_dir/Run