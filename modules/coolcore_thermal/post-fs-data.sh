#!/system/bin/sh
# 开机记录环境
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"
log "post-fs-data: uid=$(id -u), 初始温度 $(max_temp)C"
