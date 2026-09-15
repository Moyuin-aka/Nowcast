# 开发交接 · 2026-09-15

## 当前状态

这是第一份可继续开发的源码快照，不是已验证可安装的发行版。

- Mac 源码：菜单栏、设置窗口、前台应用映射、浏览器域名识别、Music 后台采集、Keychain、登录启动。
- 数据规则：应用/域名白名单、3 秒防抖、独立 activity/music、60 秒心跳。
- Tyndall 接入：动态 API、严格输入校验、180 秒 TTL、数据库并发写入函数、双状态卡片。
- 打包：Swift Package、打包脚本、GitHub Actions 通用 DMG 工作流。尚未运行 GitHub Actions。
- 未配置真实上报密钥，未执行线上数据库迁移，未部署网站，未生成可安装 DMG。

## 已验证

- `node --experimental-strip-types scripts/check-presence.mjs` 在 Tyndall 目录通过：输入结构、字段白名单、活动/音乐、清空和 TTL 边界。
- Mac 核心模块通过直接 `swiftc` 编译（非完整应用）。
- Tyndall `pnpm astro check` 报告 16 个现有页面错误，本次新增/修改的状态文件未出现在错误列表中。
- 完整网站构建通过前端编译并进入页面生成，但已有 OG 图片的 Google Fonts 下载失败：沙箱内 DNS 失败，放开网络后连接被重置。

## 尚未完成的验证

- 本机 CommandLineTools 的 Swift PackageDescription 模块/动态库不一致，`swift test` 在清单链接阶段失败。
- 绕过 SPM 直接编译完整应用时，默认 macOS 27 SDK 的 SwiftUI State 宏缺少插件。
- 尝试使用本机 macOS 15.2 SDK 的核心模块编译后，会话被中断；尚未确认该路径完整结果。
- 本地 Playwright + 模拟 Supabase 接口测试第一次无法启动本地服务器；重新申请权限时被中断，不能算通过。
- Swift XCTest、真实自动化权限、休眠/锁屏、网络恢复、签名后 Apple Events 权限、登录启动、DMG 均需继续验证。

## 换到此目录后的优先事项

1. 在一致的 Xcode/Swift 工具链上完成 `swift test` 和完整应用编译，修复编译问题。
2. 审查 Monitor：错误重试需退避，暂停后清空失败需继续重试；设置窗口在前台时音乐仍应更新。
3. 完善锁屏行为（现有休眠/会话通知不等于已验证的所有锁屏场景）。
4. 测试浏览器 JXA、Music 在后台/暂停/退出时的行为和 Automation 授权归属。
5. 执行本地端到端测试与桌面/移动端视觉检查。
6. 本地构建 DMG；推送 GitHub 后运行 CI，核实 arm64/x86_64 通用产物。
7. 真实接入时应用 SQL 迁移、设置密钥并部署 Tyndall 一次，然后安装采集器。

## 集成文件位置

`integrations/tyndall/` 保存本次 Tyndall 改动的完整文件快照，方便独立仓库继续开发。
原 Tyndall 工作区也保留这些未提交改动。它们不属于此次 Nowcast 仓库提交以外的任何已提交/已部署版本。

复制回 Tyndall 前必须逐文件比较，不能覆盖之后的无关改动。原仓库还有用户的头像删除、内容子模块等修改，不要一并提交或还原。

## 临时验证资料（非仓库依赖）

- 原暂存源码：`/private/tmp/nowcast-work`
- 直接编译产物：`/private/tmp/nowcast-direct`
- Playwright + 模拟接收端测试：`/private/tmp/nowcast-ui-test.py`
- 网站构建日志：`/private/tmp/nowcast-astro-build.log`

这些路径可能被系统清理。正式构建和文档不能依赖它们。
