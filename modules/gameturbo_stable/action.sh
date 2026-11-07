#!/system/bin/sh
# 点插件卡片上的"运行"按钮时执行，输出直接显示在界面上。
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

fg() {
  line=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=')
  echo "$line" | sed -n 's/.*{[^ ]* [^ ]* \([a-zA-Z0-9._]*\)\/.*/\1/p'
}

MODE=$(cfg MODE balanced)
FPS=$(cfg FPS auto)
PKG=$(fg)

echo "===== GameTurbo 稳帧引擎 ====="
echo "配置      : MODE=$MODE  FPS=$FPS"
echo "运行身份  : uid=$(id -u) $(is_root && echo '(root)' || echo '(shell)')"
echo "前台应用  : ${PKG:-未知}"

if [ -n "$PKG" ] && cmd game list-modes "$PKG" >/dev/null 2>&1; then
  echo "游戏识别  : 是（系统标记为 game）"
  echo "游戏模式  :"
  cmd game list-modes "$PKG" 2>&1 | sed 's/^/    /'
else
  echo "游戏识别  : 当前前台不是游戏（或未在 EXTRA_GAMES 里）"
fi

echo "刷新率    : $(settings get system min_refresh_rate) ~ $(settings get system peak_refresh_rate)"
echo "固定性能  : $(dumpsys power 2>/dev/null | grep -m1 -i 'fixed performance' | tr -d '\r' | sed 's/^ *//')"

echo ""
echo "日志: $LOGF"
echo "提示: 修改 config.conf 后重装插件生效；beast 模式更热，注意散热。"
