#!/system/bin/sh
# 卸载前把改过的东西还原，别把手机留在"performance"档上。
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

log "uninstall: 还原所有改动"

settings delete system min_refresh_rate >/dev/null 2>&1
cmd power set-fixed-performance-mode-enabled false >/dev/null 2>&1

if is_root; then
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    n=$(basename "$cpu")
    [ -f "$MODDIR/backup/$n.governor" ] && write_node "$(cat "$MODDIR/backup/$n.governor")" "$cpu/cpufreq/scaling_governor"
    [ -f "$MODDIR/backup/$n.min_freq" ] && write_node "$(cat "$MODDIR/backup/$n.min_freq")" "$cpu/cpufreq/scaling_min_freq"
  done
fi

log "  完成"
