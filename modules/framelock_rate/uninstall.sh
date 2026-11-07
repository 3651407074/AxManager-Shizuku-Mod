#!/system/bin/sh
# 卸载时恢复原始刷新率
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

apply auto
rm -f "$MODDIR/state/orig.min" "$MODDIR/state/orig.peak" "$MODDIR/state/fps"
log "uninstall: 已恢复刷新率"
