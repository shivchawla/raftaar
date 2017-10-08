# @Author: Shiv Chawla
# @Date:   2017-10-04 12:20:02
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-10-08 15:02:27

#!/bin/bash
daemon -o "$1" -l "$2" -r --name "$3" -X "bash $PWD/_cmd.sh $4 $5"
