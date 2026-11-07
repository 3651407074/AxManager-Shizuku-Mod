# 安装脚本（被 source，不要 exit）
MODDIR=$MODPATH
. "$MODPATH/common/lib.sh"

ui_print "- CoolCore 冰封温控"
ui_print "- 当前温度: $(max_temp)°C"
ui_print "- 默认只监测；root 模式下可改 config.conf 的 ALLOW_TRIP_RAISE=1 后重装"
