#!/system/bin/sh
# 点"运行"轮换档位：auto → 60 → 90 → 120 → 144 → auto
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

cur=$(current)
case "$cur" in
  ''|auto) next=60 ;;
  60) next=90 ;;
  90) next=120 ;;
  120) next=144 ;;
  *) next=auto ;;
esac

apply "$next"

echo "===== FrameLock 帧率锁 ====="
echo "当前档位: $next"
echo "min_refresh_rate = $(settings get system min_refresh_rate)"
echo "peak_refresh_rate = $(settings get system peak_refresh_rate)"
echo ""
if [ "$next" = auto ]; then
  echo "已恢复系统自动刷新率。"
else
  got=$(settings get system min_refresh_rate | tr -d '\r\n')
  if [ "$got" = "$next" ]; then
    echo "已锁定 ${next}Hz（更稳，但更耗电、更热）。"
  else
    echo "⚠ 写入 ${next}Hz 没生效（读回: ${got:-null}）"
    echo "  这台机器的 ROM 不接受直接改刷新率，需要 root 模式强制。"
  fi
fi
echo "日志: $LOGF"
