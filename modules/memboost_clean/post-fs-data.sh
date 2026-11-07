#!/system/bin/sh
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"
log "post-fs-data: 可用内存 $(mem_free_mb)MB"
