#!/system/bin/sh
# 温控守护：采样温度、记录降频；root + 配置允许时，把触发点整体后移
ASH_STANDALONE=1

MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

INTERVAL=$(cfg INTERVAL 30)
OFFSET=$(cfg TRIP_OFFSET 5000)
ALLOW=$(cfg ALLOW_TRIP_RAISE 0)
case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=30 ;; esac
[ "$OFFSET" -gt 8000 ] && OFFSET=8000

log "service start: interval=${INTERVAL}s allow_raise=$ALLOW offset=$OFFSET root=$(is_root && echo yes || echo no)"

if [ "$ALLOW" = 1 ] && is_root; then
  for z in /sys/class/thermal/thermal_zone*; do
    for t in "$z"/trip_point_*_temp; do
      [ -f "$t" ] || continue
      cur=$(cat "$t" 2>/dev/null)
      case "$cur" in ''|*[!0-9]*) continue ;; esac
      key=$(echo "$t" | tr '/' '_')
      [ -f "$MODDIR/backup/$key" ] || echo "$cur" > "$MODDIR/backup/$key"
      new=$((cur + OFFSET))
      write_node "$new" "$t" && log "  raise $(basename "$z")/$(basename "$t"): $cur -> $new"
    done
  done
else
  log "  跳过抬高触发点（需要 root + ALLOW_TRIP_RAISE=1）"
fi

while :; do
  t=$(max_temp)
  c=$(cooling_active)
  log "temp=${t}C cooling_active=$c"
  sleep "$INTERVAL"
done
