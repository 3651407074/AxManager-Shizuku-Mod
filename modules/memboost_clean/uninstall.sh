#!/system/bin/sh
# 卸载时还原 vm 参数
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

[ -f "$MODDIR/backup/swappiness" ] && write_node "$(cat "$MODDIR/backup/swappiness")" /proc/sys/vm/swappiness
[ -f "$MODDIR/backup/vfs_cache_pressure" ] && write_node "$(cat "$MODDIR/backup/vfs_cache_pressure")" /proc/sys/vm/vfs_cache_pressure
log "uninstall: vm 参数已还原"
