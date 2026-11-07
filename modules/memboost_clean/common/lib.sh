#!/system/bin/sh
# 共用函数
MODDIR=${MODDIR:-$(cd "${0%/*}/.." && pwd)}
LOG_DIR="${AXERONDIR:-/data/local/tmp}/logs"
LOGF="$LOG_DIR/${AXERON_PLUGIN:-memboost_clean}.log"
mkdir -p "$LOG_DIR" "$MODDIR/state" 2>/dev/null

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

mem_free_mb() {
  awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo 2>/dev/null
}

foreground_pkg() {
  line=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=')
  pkg=$(echo "$line" | sed -n 's/.*[ {]\([a-zA-Z0-9._]*\)\/[^ }]*}.*/\1/p')
  [ -z "$pkg" ] && pkg=$(dumpsys activity activities 2>/dev/null | grep -m1 'topResumedActivity=' | sed -n 's/.*[ {]\([a-zA-Z0-9._]*\)\/[^ }]*}.*/\1/p')
  echo "$pkg"
}

is_game() {
  [ -z "$1" ] && return 1
  cmd game list-modes "$1" >/dev/null 2>&1
}

clean_once() {
  before=$(mem_free_mb)
  if [ "$(cfg KILL_ALL 1)" = 1 ]; then
    am kill-all >/dev/null 2>&1
  fi
  if is_root; then
    sync
    write_node 3 /proc/sys/vm/drop_caches && log "  drop_caches"
  fi
  sleep 1
  after=$(mem_free_mb)
  log "  clean: ${before}MB -> ${after}MB"
  echo "$before" "$after"
}
