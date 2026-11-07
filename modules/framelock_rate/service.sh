#!/system/bin/sh
# 开机把上次选的档位重新应用一次
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

v=$(current)
[ -z "$v" ] && exit 0
log "service: 恢复档位 $v"
apply "$v"
