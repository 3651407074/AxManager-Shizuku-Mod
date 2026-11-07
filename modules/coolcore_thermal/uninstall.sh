#!/system/bin/sh
# 卸载时把抬高过的触发点还原
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

for z in /sys/class/thermal/thermal_zone*; do
  for t in "$z"/trip_point_*_temp; do
    [ -f "$t" ] || continue
    key=$(echo "$t" | tr '/' '_')
    [ -f "$MODDIR/backup/$key" ] && write_node "$(cat "$MODDIR/backup/$key")" "$t"
  done
done
log "uninstall: 温控触发点已还原"
