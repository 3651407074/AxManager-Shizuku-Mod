#!/system/bin/sh
# 手动清一次（点"运行"）
MODDIR=$(cd "${0%/*}" && pwd)
. "$MODDIR/common/lib.sh"

echo "===== MemBoost 内存加速 ====="
before=$(mem_free_mb)
echo "清理前可用: ${before} MB"

am kill-all >/dev/null 2>&1
if is_root; then
  sync
  write_node 3 /proc/sys/vm/drop_caches
  echo "Root 优化  : drop_caches 已执行"
else
  echo "Root 优化  : 跳过（shell 模式无权限）"
fi
sleep 1
after=$(mem_free_mb)
echo "清理后可用: ${after} MB"
echo "释放约    : $((after - before)) MB"
echo ""
echo "swappiness: $(cat /proc/sys/vm/swappiness 2>/dev/null)"
echo "日志: $LOGF"
