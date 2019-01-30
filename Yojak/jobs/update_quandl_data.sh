dir="/home/admin"
julia="$dir/julia/bin/julia"
PATH=:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd "$dir/yojak/jobs/" 

now="$(date +'%Y%m%d_%H:%M:%S')"
fname="$PWD/logs/Quandl_update_${now}.txt"
error_fname="$PWD/logs/Error_quandl_update_${now}.txt"

if [ ! -d "$PWD/logs/" ]; then
       mkdir "$PWD/logs"
fi      


$julia $PWD/updateQuandlData.jl 2>&1 | tee ${fname}

#!	) 3>&1 1>&2 2>&3 | tee ${error_fname}
