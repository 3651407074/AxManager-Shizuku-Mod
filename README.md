# AxManager Shizuku Mod

[AxManager](https://github.com/fahrez182/AxManager) 的非官方修改版：**修复 Android 16/17 上的激活失败**，并新增**通过 Shizuku 授权以 shell 身份启动**的第三条激活通道。

> 本仓库不重新分发上游源码，只包含**补丁**、**构建产物**和**复现文档**。上游为 Apache-2.0，版权归原作者所有，详见 [NOTICE](NOTICE)。

---

## 为什么会有这个项目

上游最新版 `3.0.0.r509` 在 **vivo V2520A / Android 17（SDK 37）** 上，无论走「无线调试激活」还是 root，都会在服务端起进程后 30 秒自杀：

```
I AxeronService: resolve manager: classPath=/data/app/~~…/base.apk
                 apks=[/data/app/~~…/base.apk] installed=0
E AxeronService: no package owns the APK this server runs from, exiting
```

根因在 `AxeronService.resolveRunningManager()`：

```kotlin
val apk = System.getProperty("java.class.path")?.substringBefore(':') ?: return null
val owner = PackageManagerApis.getInstalledPackagesNoThrow(0, 0)   // ← 这里返回空表
    .firstOrNull { it?.applicationInfo?.sourceDir == apk } ?: return null
```

Android 17 上，以 shell 身份运行的 server 调 `getInstalledPackages(0, 0)` 拿到的是**空列表**（日志里的 `installed=0` 就是它），于是匹配必然失败 → `runningManager == null` → 重试 `MANAGER_RESOLVE_TRIES` 次 → `exitProcess(MANAGER_APP_NOT_FOUND)`。表现就是「服务端起得来，但管理器永远等不到」，激活卡死在 `Stopped`。

---

## 亮点

### 1. 根因级修复，不是界面绕过

不是改文案、不是重试、不是让用户多点几次，而是直接修 `resolveRunningManager()` 的解析逻辑，加三级兜底：

| 顺序 | 匹配方式 | 作用 |
|---|---|---|
| 1 | `sourceDir` 与 `java.class.path` 精确相等 | 原始逻辑，ROM 正常时走这里 |
| 2 | 与 classpath 中 APK **同目录** | 同一路径的不同写法（`~~` 编码、软链） |
| 3 | 按包名 `frb.axeron.manager` 直接 `getPackageInfo` | 包列表整个读不到时兜底 |

并且每一步都打结构化日志：

```
I AxeronService: resolve manager: classPath=… apks=… installed=N
I AxeronService: resolve manager: matched by APK dir …
I AxeronService: resolve manager: fell back to frb.axeron.manager
```

下次再遇到同类 ROM，`installed=` 的数字就能直接定位问题，不用再猜。

### 2. 新增 Shizuku 激活通道（无 root 也能跑 shell）

原版「以 Shell 身份启动」只有一条路：`su 2000 -c …`，没 root 就是 `Unable to create a shell`。

修改后该按钮变成双通道：

1. **优先 Shizuku**：`Shizuku.pingBinder()` → 未授权则 `requestPermission()` 等待用户允许 → 用 `IShizukuService.newProcess()` 以 **uid 2000** 执行 `libaxeron.so --apk=<apk>`；
2. **自动回退 root**：Shizuku 没装/没运行/拒绝授权时，走原来完全相同的 root 逻辑，老用户行为不变。

stdout / stderr 实时打进激活日志，退出码决定成败，界面里能看到完整的 `Starter finished` 过程。

### 3. 真机验证，不是"编译通过就算完"

在 **vivo V2520A / Android 17 (SDK 37) / SELinux `u:r:shell:s0`** 上实测跑通：

- 服务端 `axeron_server` 以 **UID 2000** 常驻（`SELinux: u:r:shell:s0`）；
- 管理器卡片从 `未激活 / Stopped` 变为 `运行中 / UID 2000`；
- 日志确认兜底生效：`installed=0` → `fell back to frb.axeron.manager`。

### 4. 可复现构建

完整写清了依赖矩阵和两个真实的坑：

| 组件 | 版本 |
|---|---|
| JDK | 25（target 21） |
| Gradle | 9.8.2 |
| AGP | 9.5.0 |
| Kotlin | 2.4.21 |
| compileSdk / buildTools | 36 / 36.0.0 |
| NDK / CMake | 29.0.14206865 / 3.22.1 |

- **坑 1**：AGP 直接拒绝含非 ASCII 字符的工程路径（`Your project path contains non-ASCII characters`），工程必须放在纯英文目录下构建；
- **坑 2**：`build.gradle.kts` 在配置阶段执行 `git rev-list --count HEAD` 生成版本号，用源码 zip 构建时必须先 `git init && commit`，否则配置直接失败。

### 5. 补丁小而透明

只改 7 个文件，全部在 [axm-mod.patch](axm-mod.patch) 里，可逐行 review：

```
gradle/libs.versions.toml                                  + Shizuku 依赖版本
manager/build.gradle.kts                                   + api/provider 依赖
manager/src/main/AndroidManifest.xml                       + ShizukuProvider
manager/.../ui/viewmodel/ActivateViewModel.kt              + Shizuku 激活 + 回退
manager/src/main/res/values/strings.xml                    ~ 文案
manager/src/main/res/values-zh-rCN/strings.xml             ~ 文案
server/.../server/AxeronService.kt                         ~ 管理器解析兜底 + 日志
```

---

## 安装

> 与官方版**签名不同**，不能覆盖安装，必须先卸载（会清空 AxManager 自身的设置与插件列表）。

```bash
adb uninstall frb.axeron.manager
adb install -r AxManager-mod-shizuku-debug.apk
```

安装包见 [Releases](../../releases)（`versionName 3.0.0.r1`，`versionCode 30000`，debug 签名 `CN=AxManagerMod`）。

## 使用

**方式 A：无线调试（推荐，无需 root、无需 Shizuku）**

打开开发者选项里的「无线调试」→ 应用内点激活卡片 →「开始配对」。修复后这条路径在 Android 17 上已经可用。

**方式 B：Shizuku（无 root 时想以 shell 身份跑）**

1. 先启动 Shizuku（应用内显示「Shizuku 正在运行」）；
2. AxManager → 激活 →「直接激活（Root / Shizuku）」→ **以 Shell 身份启动**；
3. 首次弹出 Shizuku 授权框，点允许；
4. 日志出现 `Shizuku permission granted` → `Starter finished` 即成功。

**方式 C：root**

有 root 时逻辑与官方一致（`su` 或 `su 2000 -c`）。

## 构建

见 [docs/BUILD.md](docs/BUILD.md)。

## 已知限制

- 当前产物是 **debug 构建**（未混淆、体积大、含 4 个 ABI），仅供测试；
- 修复属于**服务端解析层兜底**，没有改原生 starter（`libaxeron.so`），属于"绕过硬伤"而非让原生层也正确；
- 版本号显示为 `3.0.0.r1`（本地 git 提交数为 1），`versionCode` 保持 `30000` 以兼容服务端更新判断；
- 未在 Android 14/15 上回归测试。

## 许可证与致谢

- 本仓库的补丁与文档：**Apache-2.0**，见 [LICENSE](LICENSE)；
- 上游 [AxManager](https://github.com/fahrez182/AxManager) © 2025-2026 FahrezRB，Apache-2.0；
- 上游内含 [Shizuku](https://github.com/RikkaApps/Shizuku)（© RikkaApps）等第三方组件，完整声明见 [NOTICE](NOTICE)；
- 本项目与上游作者**无隶属关系**，不代表上游立场；问题请在本仓库提，不要打扰上游。
