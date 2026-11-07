# 安装脚本（被 source，不要 exit）
MODDIR=$MODPATH
. "$MODPATH/common/lib.sh"

ui_print "- MemBoost 内存加速"
ui_print "- 当前可用内存: $(mem_free_mb) MB"
ui_print "- 默认进入游戏时自动清一次后台（ON_GAME_START=1）"
