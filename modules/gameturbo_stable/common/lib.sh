#!/system/bin/sh
# 共用函数：日志、配置、节点读写。所有脚本都会 source 这个文件。

MODDIR=${MODDIR:-$(cd "${0%/*}/.." && pwd)}
LOG_DIR="${AXERONDIR:-/data/local/tmp}/logs"
LOGF="$LOG_DIR/${AXERON_PLUGIN:-gameturbo_stable}.log"
mkdir -p "$LOG_DIR" 2>/dev/null

log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGF" 2>/dev/null
}

is_root() { [ "$(id -u)" = 0 ]; }

cfg() {
  # cfg KEY DEFAULT
  v=$(grep -E "^$1=" "$MODDIR/config.conf" 2>/dev/null | tail -n 1 | cut -d= -f2- | tr -d '\r')
  if [ -n "$v" ]; then echo "$v"; else echo "$2"; fi
}

write_node() {
  # write_node VALUE PATH，成功返回 0
  [ -n "$2" ] && [ -w "$2" ] || return 1
  echo "$1" > "$2" 2>/dev/null || return 1
  return 0
}
