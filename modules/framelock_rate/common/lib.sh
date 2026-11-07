#!/system/bin/sh
# 共用函数
MODDIR=${MODDIR:-$(cd "${0%/*}/.." && pwd)}
LOG_DIR="${AXERONDIR:-/data/local/tmp}/logs"
LOGF="$LOG_DIR/${AXERON_PLUGIN:-framelock_rate}.log"
mkdir -p "$LOG_DIR" "$MODDIR/state" 2>/dev/null

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGF" 2>/dev/null; }

current() { cat "$MODDIR/state/fps" 2>/dev/null | tr -d '\r\n'; }

save_originals() {
  [ -f "$MODDIR/state/orig.min" ] || settings get system min_refresh_rate > "$MODDIR/state/orig.min" 2>/dev/null
  [ -f "$MODDIR/state/orig.peak" ] || settings get system peak_refresh_rate > "$MODDIR/state/orig.peak" 2>/dev/null
}

apply() {
  v="$1"
  echo "$v" > "$MODDIR/state/fps"
  if [ "$v" = auto ]; then
    r=$(cat "$MODDIR/state/orig.min" 2>/dev/null | tr -d '\r\n')
    p=$(cat "$MODDIR/state/orig.peak" 2>/dev/null | tr -d '\r\n')
    if [ -n "$r" ] && [ "$r" != null ]; then settings put system min_refresh_rate "$r"; else settings delete system min_refresh_rate; fi
    if [ -n "$p" ] && [ "$p" != null ]; then settings put system peak_refresh_rate "$p"; else settings delete system peak_refresh_rate; fi
    log "apply auto (min=$r peak=$p)"
  else
    save_originals
    settings put system min_refresh_rate "$v" >/dev/null 2>&1
    settings put system peak_refresh_rate "$v" >/dev/null 2>&1
    got=$(settings get system min_refresh_rate | tr -d '\r\n')
    if [ "$got" != "$v" ]; then
      log "WARN: 写入 $v Hz 后读回 '$got'，ROM 没接受（需要 root 才能强制）"
    else
      log "apply lock $v Hz"
    fi
  fi
}
