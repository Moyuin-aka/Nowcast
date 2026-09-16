# Nowcast · 此刻

A small macOS menu bar app that turns what you are doing into a provider-neutral API.

把此刻，轻轻广播。前台写代码，后台听音乐；网站自动更新，无需重新部署。

> 当前为开发预览：CI 已完成完整应用与 universal DMG 构建验证；Developer ID 发布链路已接入，下一份正式 DMG 仍需配置 Apple 发布凭据后生成。详见 [开发交接](DEVELOPMENT.md)。

## 第一版

- VS Code → 写代码；Terminal / iTerm2 / Ghostty / Warp → Vibe Coding；Obsidian → 写作。
- 浏览器当前网站 → B站、小红书、GitHub、AI 服务；未知网站只显示「浏览网页」。
- Apple Music 单独采集，可与前台活动同时展示。
- 3 秒切换防抖，60 秒心跳，服务端 180 秒过期。断网只保留最新状态，不补传历史。
- 菜单栏预览、暂停共享、登录启动、JSON 自定义规则。
- HTTPS 上报，写入密钥存 macOS Keychain，拒绝跟随重定向。
- 原生 Swift / AppKit / SwiftUI，macOS 13+，无第三方运行时依赖。MIT。

## 安装与初次使用

1. 从 GitHub Releases 下载对应版本的 universal DMG。开发预览也可以从 **Build and release macOS app**
   workflow 的 artifact 下载，或自行执行下方构建命令。
2. 将 DMG 中的 Nowcast 拖到 Applications，打开。
3. 默认暂停共享。填写自己的 API 地址和写入密钥，保存，然后「开始共享」。
   不填地址时也可开始采集，在菜单栏本地预览；不会上传。
4. 首次读取浏览器 / Music 时允许 macOS 的「自动化」授权。没有权限时显示提示并降级。
5. 需要时勾选「登录时启动」。此操作不会在安装时自动开启。

Pull request 和普通分支的 Actions 产物仍是 **ad-hoc 签名**，只用于构建验证；下载后可能被 Gatekeeper 阻止。
tag 发布会强制要求 Developer ID Application 签名、公证与 staple，任一步缺失或失败都不会创建 GitHub Release。
不要关闭系统安全功能。Apple 凭据配置方法见 [签名发布说明](docs/releasing.md)。

## 本地开发

```sh
swift test
bash scripts/package.sh native
# 完整 Xcode 环境，可构建 Apple Silicon + Intel 通用版本：
bash scripts/package.sh universal
```

输出：`dist/Nowcast.app`、`dist/Nowcast-<version>-native.dmg` 和 SHA-256 校验文件。
仓库根目录的 `VERSION` 是唯一发布版本源。CLI 工具链不足以构建通用二进制时，使用 Xcode / Actions。
请运行打包后的 `.app`；直接 `swift run` 的权限归属和登录启动行为不代表分发版。

推送与 `VERSION` 完全一致的 `vX.Y.Z` tag 后，GitHub Actions 会测试并验证通用 DMG，再自动创建
GitHub Release。应用的 `CFBundleShortVersionString`、DMG 文件名、artifact 名称和 Release tag 均来自同一版本；
CI run number 写入 `CFBundleVersion`，用于区分构建。tag 产物还会验证 Developer ID 身份、notarization ticket
和 Gatekeeper 评估，再交给 Release job 发布。

## 配置规则

「编辑规则」打开 `~/Library/Application Support/Nowcast/config.json`。
暂停共享，修改并保存文件，点击「重新载入」。错误配置不会悄悄覆盖旧配置。

```json
{
  "endpoint": "https://example.com/api/presence",
  "collectBrowser": true,
  "collectMusic": true,
  "apps": {
    "md.obsidian": {"kind": "writing", "title": "写作", "source": "Obsidian"}
  },
  "domains": {
    "bilibili.com": {"kind": "browsing", "title": "逛 B站", "source": "B站"}
  }
}
```

这是最小配置示例，替换完整配置会替换规则全集。应用用 bundle ID 匹配；域名匹配自身及其子域，
较具体的域名优先，`evilbilibili.com` 不会匹配 `bilibili.com`。
支持 kind：`coding`、`vibe`、`writing`、`ai`、`browsing`、`reading`、`video`、`game`、`other`。

浏览器脚本适配：Safari、Chrome、Edge、Arc、Brave；各版本授权及脚本兼容性需在目标设备验证。
Firefox 暂无标签页细分适配。不会读取页面正文；站点识别不等同于「视频正在播放」。
Music 只读取本机 Music.app，不追踪 iPhone 上独立播放的音乐。第一版没有专辑封面和播放进度条。

## HTTP 协议 v1

```http
POST /api/presence
Content-Type: application/json
x-now-playing-secret: <your-secret>
```

```json
{
  "version": 1,
  "activity": {"kind": "writing", "title": "写作", "source": "Obsidian", "startedAt": "2026-09-15T10:00:00Z"},
  "music": {"state": "playing", "title": "Example song", "artist": "Example artist", "album": "Example album"},
  "observedAt": "2026-09-15T10:23:00Z"
}
```

暂停音乐时 `music: null`；未知应用时 `activity: null`；暂停共享 / 休眠时两者均为 null。
`observedAt` 是当前采集时间；`startedAt` 是活动开始时间，心跳不会重置它。
服务器必须自行记录接收时间，拒绝过旧/未来时间和越序数据，180 秒无心跳后不再返回 live。
只为最新状态设计，不是活动历史数据库。第一版按单用户、单台 Mac 设计。

接收端成功返回任意 2xx；401 表示密钥错误；其他状态视为失败。重试会发送最新采样。
HTTPS 必需；本机 `localhost` / `127.0.0.1` 允许 HTTP 调试。

## 接入个人网站

Nowcast 不依赖特定网站框架、数据库或托管平台。接收端只需实现
[presence protocol v1](docs/protocol-v1.md)，接收端行为与仓库隐私边界见
[receiver integrations](docs/integrations.md)。所有公开示例使用合成数据，不包含个人站点的部署信息。

站点侧的 API 实现、数据库迁移、页面组件、环境变量清单和部署说明保留在各自站点仓库中，
不会作为快照收进 Nowcast。典型接入流程是：站点实现受保护的写入端点和带过期机制的公开读取端点，
在本地用合成 payload 验证，再把端点与站点自行生成的密钥填入 Nowcast。

## 验证清单

- 切换 VS Code → Terminal → Obsidian，停留超过 3 秒；快速切换不反复广播。
- 浏览 B站后切换普通网站；API 不包含原始 URL。
- 后台 Music 换歌、暂停、退出；前台活动保留，音乐独立更新。
- 暂停共享后 GET 不再返回活动；Mac 睡眠或断网，180 秒后状态过期。
- 浏览器拒绝自动化权限时，保持通用浏览状态并显示可操作的提示。
- API 401 / 503 时能看到失败状态，恢复后只上传当前活动。

睡眠/会话退出通知用于主动清除，网络发送是尽力而为；接收端 TTL 是最终保证。
无需辅助功能权限来读取应用 bundle ID；浏览器与 Music 自动化权限由系统按应用授权。
