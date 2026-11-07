#!/system/bin/sh
# 开机（或插件启用/更新后）先跑一次：建目录、记一笔环境，真正的调度在 service.sh 里。
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

mkdir -p "$MODDIR/backup" "$MODDIR/state" 2>/dev/null
log "post-fs-data: boot, uid=$(id -u), AXERONVER=${AXERONVER:-?}"
log "  mode=$(cfg MODE balanced) fps=$(cfg FPS auto)"
