# 构建说明

目标：从上游源码 + 本仓库补丁，产出一个可安装的 `AxManager-mod-shizuku-debug.apk`。

## 1. 环境

| 组件 | 版本 | 备注 |
|---|---|---|
| JDK | 25（`javac --version` 验证；工程 target 为 21） | Gradle 9.8.2 支持 JDK 25 |
| Android SDK | `platforms;android-36`、`build-tools;36.0.0`、`platform-tools` | |
| NDK | `29.0.14206865` | 工程 `ndkVersion` 写死该版本 |
| CMake | `3.22.1` | 编译 `libaxeron.so` 等原生库 |
| Gradle | 9.8.2 | 由 `gradlew` 自动下载 |
| Git | 任意版本 | 仅用于生成版本号 |

安装 SDK 组件（`sdkmanager` 需先接受 licenses）：

```bash
sdkmanager --sdk_root=/android-sdk \
  "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "ndk;29.0.14206865" "cmake;3.22.1"
```

## 2. 取源码

```bash
# 主仓库
curl -L -o src.zip https://codeload.github.com/fahrez182/AxManager/zip/refs/heads/main

# 子模块 api（settings.gradle.kts 依赖它）
curl -L -o api.zip https://codeload.github.com/fahrez182/Axeron-API/zip/refs/heads/main
```

解压后把 `Axeron-API-main` 的内容放到 `AxManager-main/api/`。

> **坑 0**：上层工程路径必须是纯英文。AGP 会直接报
> `Your project path contains non-ASCII characters`，中文目录会构建失败。

## 3. 打补丁

```bash
cd AxManager-main
git apply ../axm-mod.patch
```

补丁包含 7 个文件的改动（见 README「补丁小而透明」）。

## 4. 版本号所需的 git 历史

`build.gradle.kts` 在**配置阶段**执行：

```kotlin
val gitCommitCount = providers.exec {
    commandLine("git", "rev-list", "--count", "HEAD")
}.standardOutput.asText.get().trim().toInt()
```

用 zip 源码构建时没有 `.git`，这一行会直接抛 `Could not start 'git'` 或 `not a git repository`。

```bash
git init
git config user.email "you@example.com"
git config user.name  "you"
git add -A && git commit -m "baseline"
```

提交数即 `versionName` 里的 `rN`（本产物为 `r1`）。`versionCode` 来自 `api/manifest.gradle.kts` 的 `api_version_code`，保持 `30000` 不要动，服务端靠它判断是否需要更新。

## 5. 签名

`manager/build.gradle.kts` 的 debug/release 都用名为 `frb-project` 的 signingConfig，从 `local.properties` 读取：

```properties
sdk.dir=/android-sdk
signing.storeFile=/path/to/build.jks
signing.storePassword=123456
signing.keyAlias=axm
signing.keyPassword=123456
```

生成自签名证书：

```bash
keytool -genkeypair -keystore build.jks -alias axm -keyalg RSA -keysize 2048 \
        -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=AxManagerMod,O=Mod,C=CN"
```

> `-dname` 里不要带空格，keytool 会把它拆成两个参数。

## 6. 构建

```bash
./gradlew :manager:assembleDebug --no-daemon --console=plain
```

产物：

```
manager/build/outputs/apk/debug/AxManager_v3.0.0.r1_30000-debug_<时间戳>.apk
```

首次构建会下载 AGP / Compose / NDK 工具链，约 10–20 分钟；增量构建 1 分钟左右。

`stripDebugDebugSymbols` 阶段可能出现 `llvm-strip: … not recognized as a valid object file` 的告警，不影响产物（这些 `.so` 是预编译的 jniLibs）。

## 7. 安装与验证

```bash
adb uninstall frb.axeron.manager      # 签名不同，必须卸载
adb install -r AxManager_v*.apk
adb logcat -s AxeronService | grep "resolve manager"
```

预期日志：

```
resolve manager: classPath=…/base.apk apks=[…] installed=0
resolve manager: fell back to frb.axeron.manager
```

服务端起来后：

```bash
adb shell ps -A | grep axeron_server
# shell  12345  1  …  S axeron_server
```

界面卡片显示 `运行中 / UID 2000` 即成功。
