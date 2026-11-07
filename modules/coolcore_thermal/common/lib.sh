#!/system/bin/sh
# 共用函数
MODDIR=${MODDIR:-$(cd "${0%/*}/.." && pwd)}
LOG_DIR="${AXERONDIR:-/data/local/tmp}/logs"
LOGF="$LOG_DIR/${AXERON_PLUGIN:-coolcore_thermal}.log"
mkdir -p "$LOG_DIR" "$MODDIR/state" "$MODDIR/backup" 2>/dev/null

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGF" 2>/dev/null; }

is_root() { [ "$(id -u)" = 0 ]; }

cfg() {
  v=$(grep -E "^$1=" "$MODDIR/config.conf" 2>/dev/null | tail -n 1 | cut -d= -f2- | tr -d '\r')
  if [ -n "$v" ]; then echo "$v"; else echo "$2"; fi
}

write_node() {
  [ -n "$2" ] && [ -w "$2" ] || return 1
  echo "$1" > "$2" 2>/dev/null || return 1
  return 0
}

# 输出当前最高温度（摄氏度，取整）
max_temp() {
  max=0
  for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    case "$v" in ''|*[!0-9-]*) continue ;; esac
    [ "$v" -gt "$max" ] && max=$v
  done
  echo $((max / 1000))
}

# 当前有多少个 cooling device 在动（>0 说明正在压制性能）
cooling_active() {
  n=0
  for f in /sys/class/thermal/cooling_device*/cur_state; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    case "$v" in ''|*[!0-9-]*) continue ;; esac
    [ "$v" -gt 0 ] && n=$((n + 1))
  done
  echo "$n"
}
