# AxManager 性能模块包 · 4 个

给 [AxManager](../README.md) 写的 4 个插件模块，围绕一个目标：**打游戏时尽量稳住帧率**（类似红魔"烫也不掉帧"的思路：先给足性能，再谈散热）。

名字都是「英文代号 + 中文说明」，一眼知道干什么。

| 模块 | 名字 | 一句话 | 无 root 能用吗 |
|---|---|---|---|
| `gameturbo_stable` | **GameTurbo 稳帧引擎** | 检测到游戏 → 切性能档、锁高刷、满频；退出即还原 | 部分（识别+游戏模式） |
| `coolcore_thermal` | **CoolCore 冰封温控** | 实时温度监控，Root 下可把温控触发点整体后移 | 只能监测 |
| `framelock_rate` | **FrameLock 帧率锁** | 一键锁 60/90/120/144Hz 或恢复自动 | 看 ROM（见实测） |
| `memboost_clean` | **MemBoost 内存加速** | 进游戏前清后台腾内存，Root 下调 vm 参数 | ✅ 可用 |

安装包在 `dist/`：`gameturbo_stable.zip`、`coolcore_thermal.zip`、`framelock_rate.zip`、`memboost_clean.zip`。

---

## 安装

1. 把 zip 传到手机（数据线、微信文件传输都行）；
2. 打开 AxManager → **插件** → 安装（选 zip）；
3. 装完**重启插件**（或重启手机）生效；
4. 插件卡片上的「运行」按钮 = 执行该模块的 `action.sh`（看状态 / 手动触发）。

卸载/禁用时，每个模块都会执行自己的 `uninstall.sh`，把改过的设置**还原**。

---

## 1. GameTurbo 稳帧引擎

**做什么**

- 每 5 秒看一眼前台应用（`dumpsys window` → `mCurrentFocus`）；
- 判定为游戏后：`cmd game mode performance <包名>`；`balanced/beast` 档再锁刷新率；`beast` 档开固定性能模式；
- **Root 模式**额外接管：所有 CPU 核 `scaling_governor=performance` + `scaling_min_freq` 拉满、GPU governor 拉满（原值备份到 `backup/`）；
- 退出游戏立刻还原，进程被 SIGTERM 时也会还原。

**配置 `config.conf`**

```ini
MODE=balanced     # safe | balanced | beast
FPS=auto          # auto | 60 | 90 | 120 | 144
EXTRA_GAMES=      # 手动指定游戏包名，空格分隔，如 com.tencent.tmgp.sgame
INTERVAL=5        # 前台检测间隔（秒）
HEURISTIC=0       # 1 = 系统没标记 game 时按包名关键词猜
```

**为什么需要 `EXTRA_GAMES`**：Android 的 `cmd game` 只认清单里 `android:appCategory="game"` 的应用，国行 ROM 经常不给游戏打这个标（实测《和平精英》`com.tencent.tmgp.pubgmhd` 就没标）。所以：

```ini
EXTRA_GAMES=com.tencent.tmgp.pubgmhd com.tencent.tmgp.sgame
```

写进去就能被当成游戏处理（只是 `cmd game mode` 那一步会被跳过，其余照常）。

---

## 2. CoolCore 冰封温控

**做什么**

- 每 30 秒采样所有 `thermal_zone*/temp`，记录最高温和「有几个 cooling device 正在压制性能」；
- **Root + `ALLOW_TRIP_RAISE=1`** 时，把所有 `trip_point_*_temp` 整体后移（默认 +5°C，最多 +8°C），让系统更晚降频 —— 这就是"热但不掉帧"的来源，代价是更烫；
- 动作按钮：打印最热的 5 个传感器 + 温控状态。

```ini
INTERVAL=30
ALLOW_TRIP_RAISE=0   # 默认 0：只看不动
TRIP_OFFSET=5000     # 毫摄氏度，+5°C
```

> 默认只监测。抬触发点必须自己开，且只在 root 模式生效 —— 这是安全设计，不是能力缺失。

---

## 3. FrameLock 帧率锁

**做什么**

- 点一次「运行」轮换一档：`auto → 60 → 90 → 120 → 144 → auto`；
- 写入 `settings put system min_refresh_rate / peak_refresh_rate`；
- 选择记在 `state/fps`，开机由 `service.sh` 自动恢复；
- 恢复 auto 时回到安装时备份的原始值。

**实测**：在 vivo V2520A（Android 17）上，写入命令返回成功，但**读回仍是 null** —— 系统把刷新率覆盖掉了。所以模块会做一次 readback，不一致就在界面直说「ROM 没接受，需要 root 强制」，不糊弄人。

---

## 4. MemBoost 内存加速

**做什么**

- 「运行」按钮：`am kill-all` 清后台，Root 下再 `drop_caches`，前后对比可用内存；
- 守护进程：检测到**从非游戏切到游戏**时自动清一次（同一局不重复清）；
- Root 下开机把 `vm.swappiness=10`、`vm.vfs_cache_pressure=50` 调好，卸载还原。

```ini
ON_GAME_START=1   # 进游戏自动清一次
KILL_ALL=1        # 1=连缓存进程一起杀（可能杀掉后台音乐/下载）
INTERVAL=10
```

实测一次清理释放约 **331 MB**（3997 → 4328 MB），这是四个模块里在没有 root 的手机上**最立竿见影**的一个。

---

## 实测能力边界（重要）

在 **vivo V2520A / Android 17 / AxManager 以 shell（uid 2000）运行** 的环境下逐项验证：

| 操作 | 结果 |
|---|---|
| `am kill-all` | ✅ 可用，实际释放 331 MB |
| 读 `/sys/class/thermal/*`、cooling_device | ✅ 可读 |
| 读 `/proc/meminfo`、`swappiness` | ✅ 可读 |
| `dumpsys window` 取前台包名 | ✅ 可用（已修好正则） |
| `cmd game list-modes` | ✅ 可调用，但只对 `appCategory=game` 的包有效 |
| `cmd game mode performance <包>` | ❌ 非 game 类型包直接报错 |
| `settings put system min_refresh_rate` | ⚠️ 命令成功、值读回 null（ROM 覆盖） |
| `cmd power set-fixed-performance-mode-enabled` | ❌ 失败 |
| 写 `/sys/.../scaling_governor` | ❌ `Permission denied`（shell 无权限） |

**结论**：不 root 的情况下，任何 App（包括 AxManager）都改不了内核调频和温控 —— 那是内核权限。所以：

- **无 root**：GameTurbo 负责识别与记录、FrameLock 试一把、MemBoost 真能清内存、CoolCore 负责看温度；
- **有 root**（AxManager 以 Root 启动）：四个模块的能力才完整 —— 满频、抬温控触发点、锁帧、vm 调参。

这不是模块写得不够狠，而是权限边界。想清楚这一点，用起来就不会有落差。

---

## 安全说明

- 所有模块都**只做可逆操作**，原值备份在模块目录的 `backup/`，卸载时还原；
- `beast` 档与 `ALLOW_TRIP_RAISE=1` 会让手机更热，属于"用寿命换帧率"，自己权衡；
- `MemBoost` 的 `am kill-all` 会杀掉后台应用（音乐、下载、聊天），介意就把 `ON_GAME_START=0`；
- 没做任何"改分区 / 写 boot / 禁用温控驱动"的危险操作。
