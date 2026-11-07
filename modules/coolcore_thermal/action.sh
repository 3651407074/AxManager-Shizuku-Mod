#!/system/bin/sh
# 显示温度概况（点"运行"）
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

echo "===== CoolCore 冰封温控 ====="
echo "最高温度  : $(max_temp)°C"
echo "正在压制  : $(cooling_active) 个 cooling device"
echo "运行身份  : uid=$(id -u) $(is_root && echo '(root)' || echo '(shell)')"
echo ""
echo "最热的 5 个传感器："
for f in /sys/class/thermal/thermal_zone*/temp; do
  [ -r "$f" ] || continue
  v=$(cat "$f" 2>/dev/null)
  case "$v" in ''|*[!0-9-]*) continue ;; esac
  z=${f%/temp}
  type=$(cat "$z/type" 2>/dev/null)
  echo "$v ${type:-$(basename "$z")}"
done | sort -rn | head -n 5 | awk '{printf "  %-18s %d°C\n", $2, $1/1000}'

echo ""
if [ "$(cfg ALLOW_TRIP_RAISE 0)" = 1 ] && is_root; then
  echo "触发点后移: 已开启 (+$(cfg TRIP_OFFSET 5000) m°C)"
else
  echo "触发点后移: 关闭（默认只监测；root 下改 config.conf 可开启）"
fi
echo "日志: $LOGF"
