#!/system/bin/sh
# 进游戏自动清一次；不会每局都清，只在"从非游戏切到游戏"时清
ASH_STANDALONE=1

MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

INTERVAL=$(cfg INTERVAL 10)
case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=10 ;; esac

log "service start: on_game_start=$(cfg ON_GAME_START 1) kill_all=$(cfg KILL_ALL 1)"

# Root 下把 vm 参数调成"少用 swap、多留缓存命中"
if is_root; then
  for kv in "vm.swappiness 10" "vm.vfs_cache_pressure 50"; do
    f=/proc/sys/$(echo "$kv" | cut -d' ' -f1 | tr '.' '/')
    v=$(echo "$kv" | cut -d' ' -f2)
    mkdir -p "$MODDIR/backup"
    [ -f "$MODDIR/backup/$(basename "$f")" ] || cat "$f" > "$MODDIR/backup/$(basename "$f")" 2>/dev/null
    write_node "$v" "$f" && log "  $f = $v"
  done
fi

LAST=""
[ "$(cfg ON_GAME_START 1)" = 1 ] || { log "  自动清理已关闭"; exit 0; }

while :; do
  pkg=$(foreground_pkg)
  if is_game "$pkg" && [ "$pkg" != "$LAST" ]; then
    log "game detected: $pkg"
    clean_once >/dev/null
    LAST="$pkg"
  elif ! is_game "$pkg"; then
    LAST=""
  fi
  sleep "$INTERVAL"
done
