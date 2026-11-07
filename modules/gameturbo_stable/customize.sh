# customize.sh 由 AxManager 的安装器 source（不是执行），不要用 exit，用 abort。
MODDIR=$MODPATH
. "$MODPATH/common/lib.sh"

ui_print "- GameTurbo 稳帧引擎"
ui_print "- 模式: $(grep -E '^MODE=' "$MODPATH/config.conf" | cut -d= -f2)"
ui_print "- 前台检测间隔: $(grep -E '^INTERVAL=' "$MODPATH/config.conf" | cut -d= -f2) 秒"
ui_print "- 装好后重启插件（或重启手机）生效"
