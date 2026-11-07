#!/system/bin/sh
# GameTurbo 稳帧引擎 —— 守护进程
# 前台是游戏时切性能档，退出游戏立刻还原。全部操作都先探测能力，做不到就写日志跳过。
ASH_STANDALONE=1

MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

MODE=$(cfg MODE balanced)
FPS=$(cfg FPS auto)
EXTRA=$(cfg EXTRA_GAMES "")
INTERVAL=$(cfg INTERVAL 5)
case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=5 ;; esac

log "service start: mode=$MODE fps=$FPS root=$(is_root && echo yes || echo no)"

CURRENT=""

foreground_pkg() {
  line=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=')
  pkg=$(echo "$line" | sed -n 's/.*{[^ ]* [^ ]* \([a-zA-Z0-9._]*\)\/.*/\1/p')
  if [ -z "$pkg" ]; then
    line=$(dumpsys activity activities 2>/dev/null | grep -m1 'topResumedActivity=')
    pkg=$(echo "$line" | sed -n 's/.*{[^ ]* [^ ]* \([a-zA-Z0-9._]*\)\/.*/\1/p')
  fi
  echo "$pkg"
}

is_game() {
  [ -z "$1" ] && return 1
  case " $EXTRA " in *" $1 "*) return 0 ;; esac
  # 系统只允许对 android:appCategory="game" 的包用游戏模式命令
  cmd game list-modes "$1" >/dev/null 2>&1 && return 0
  [ "$(cfg HEURISTIC 0)" = 1 ] && echo "$1" | grep -qiE '(tmgp|\.game|games|mihoyo|netease|pubg|mobile)' && return 0
  return 1
}

save_original() {
  # save_original NAME PATH
  [ -f "$MODDIR/backup/$1" ] || { mkdir -p "$MODDIR/backup"; cat "$2" > "$MODDIR/backup/$1" 2>/dev/null; }
}

root_tune() {
  action="$1"
  mkdir -p "$MODDIR/backup"
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    cpufreq="$cpu/cpufreq"
    [ -d "$cpufreq" ] || continue
    n=$(basename "$cpu")
    if [ "$action" = on ]; then
      save_original "$n.governor" "$cpufreq/scaling_governor"
      save_original "$n.min_freq" "$cpufreq/scaling_min_freq"
      write_node performance "$cpufreq/scaling_governor" && log "  cpu$n governor -> performance"
      max=$(cat "$cpufreq/cpuinfo_max_freq" 2>/dev/null)
      [ -n "$max" ] && write_node "$max" "$cpufreq/scaling_min_freq"
    else
      [ -f "$MODDIR/backup/$n.governor" ] && write_node "$(cat "$MODDIR/backup/$n.governor")" "$cpufreq/scaling_governor"
      [ -f "$MODDIR/backup/$n.min_freq" ] && write_node "$(cat "$MODDIR/backup/$n.min_freq")" "$cpufreq/scaling_min_freq"
    fi
  done
  for g in /sys/class/kgsl/kgsl-3d0 /sys/class/devfreq/*gpu* /sys/class/devfreq/*.mali; do
    [ -d "$g" ] || continue
    if [ "$action" = on ]; then
      save_original "gpu.$(echo "$g" | tr '/' '_').governor" "$g/devfreq/governor"
      write_node performance "$g/devfreq/governor" && log "  gpu $(basename "$g") governor -> performance"
    else
      f="$MODDIR/backup/gpu.$(echo "$g" | tr '/' '_').governor"
      [ -f "$f" ] && write_node "$(cat "$f")" "$g/devfreq/governor"
    fi
  done
}

apply_profile() {
  pkg="$1"
  log "game start: $pkg"
  if cmd game list-modes "$pkg" >/dev/null 2>&1; then
    cmd game mode performance "$pkg" >/dev/null 2>&1 && log "  game mode -> performance"
  else
    log "  系统未把该包标为 game，跳过 game mode（可用 EXTRA_GAMES 或系统游戏空间添加）"
  fi
  if [ "$MODE" = beast ]; then
    cmd power set-fixed-performance-mode-enabled true >/dev/null 2>&1 \
      && log "  fixed performance mode -> on"
  fi
  if [ "$MODE" != safe ] && [ "$FPS" != auto ] && [ -n "$FPS" ]; then
    mkdir -p "$MODDIR/state"
    [ -f "$MODDIR/state/orig.min" ] || settings get system min_refresh_rate > "$MODDIR/state/orig.min" 2>/dev/null
    settings put system min_refresh_rate "$FPS" >/dev/null 2>&1 && log "  min refresh -> $FPS"
  fi
  if is_root; then
    root_tune on
  else
    log "  shell 模式：跳过 CPU/GPU 调频（需要 root 模式才有权限写 /sys）"
  fi
}

restore_profile() {
  pkg="$1"
  log "game exit: $pkg"
  cmd game mode standard "$pkg" >/dev/null 2>&1
  cmd power set-fixed-performance-mode-enabled false >/dev/null 2>&1
  if [ -f "$MODDIR/state/orig.min" ]; then
    o=$(tr -d '\r\n' < "$MODDIR/state/orig.min")
    if [ -n "$o" ] && [ "$o" != null ]; then
      settings put system min_refresh_rate "$o" >/dev/null 2>&1
    else
      settings delete system min_refresh_rate >/dev/null 2>&1
    fi
  fi
  is_root && root_tune off
  log "  已还原"
}

trap '[ -n "$CURRENT" ] && restore_profile "$CURRENT"; exit 0' TERM INT

while :; do
  pkg=$(foreground_pkg)
  if is_game "$pkg"; then
    if [ "$pkg" != "$CURRENT" ]; then
      [ -n "$CURRENT" ] && restore_profile "$CURRENT"
      apply_profile "$pkg"
      CURRENT="$pkg"
    fi
  elif [ -n "$CURRENT" ]; then
    restore_profile "$CURRENT"
    CURRENT=""
  fi
  sleep "$INTERVAL"
done
