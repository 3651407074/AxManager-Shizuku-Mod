# 安装脚本（被 source，不要 exit）
MODDIR=$MODPATH
. "$MODPATH/common/lib.sh"

save_originals
ui_print "- FrameLock 帧率锁"
ui_print "- 原始刷新率: $(cat "$MODPATH/state/orig.min" 2>/dev/null) / $(cat "$MODPATH/state/orig.peak" 2>/dev/null)"
ui_print "- 装好后点插件卡片的「运行」轮换档位"
