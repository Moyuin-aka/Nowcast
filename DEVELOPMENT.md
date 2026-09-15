# 开发交接 · 2026-09-15

## 当前状态

这是第一份可继续开发的源码快照，还不是经过真实使用验证的发行版。

- Mac 源码：菜单栏、设置窗口、前台应用映射、浏览器域名识别、Music 后台采集、Keychain、登录启动。
- 数据规则：应用/域名白名单、3 秒防抖、独立 activity/music、60 秒心跳。
- 通用接入：协议 v1 与接收端行为约束已独立成文档；站点实现不属于本仓库。
- 工程化：Copilot 仓库/路径指引、PR 模板、统一版本源、通用 DMG 验证和 tag 自动 Release workflow 已加入。
- 打包：远端 macOS runner 已通过 `swift test`、universal DMG 构建、双架构、签名、版本元数据、DMG 和校验和验证。
- 未配置真实接收端或上报密钥，未测试 tag 对应的 Release 发布任务。

## 已验证

- Mac 核心模块通过直接 `swiftc` 编译。
- GitHub macOS runner 上的 XCTest 与 universal 应用/DMG 完整构建通过。
- `VERSION`、tag 对应关系、shell 语法、plist、workflow YAML 和仓库隐私扫描通过。
- Actions 使用完整 commit SHA，PR 构建保持只读权限，写权限只存在于 tag release job。

## 尚未完成的验证

- 本机 CommandLineTools 的 Swift PackageDescription 模块/动态库不一致，`swift test` 在清单链接阶段失败；远端完整 Xcode 环境不受影响。
- 真实浏览器与 Music Automation 权限、休眠/锁屏、网络恢复、登录启动和安装后的权限归属仍需验证。
- ad-hoc 签名 DMG 已构建验证；Developer ID 签名、公证和 staple 尚未用真实凭据运行。
- 首个 `vX.Y.Z` tag 尚未创建，因此自动 GitHub Release 任务尚未执行。

## 下一步优先事项

1. 审查 Monitor：错误重试增加退避；暂停后清空失败继续重试；设置窗口在前台时 Music 仍更新。
2. 完善锁屏行为，并验证睡眠、会话切换和唤醒后的状态清理。
3. 测试浏览器 JXA、Music 后台/暂停/退出，以及 Automation 拒绝后的降级提示。
4. 使用本地 mock receiver 和合成 payload 做完整端到端测试。
5. 安装 workflow 产出的 DMG，验证菜单栏、设置、Keychain、登录启动和权限归属。
6. 准备首个 release tag，验证自动 Release 与下载后的 SHA-256 校验。

## 仓库边界

本仓库只保存 macOS 客户端、公开协议、接收端契约、测试和发布工具。任何真实网站的 API 实现、数据库迁移、页面组件、环境变量清单、部署说明、域名、账号和运行数据都保留在对应网站自己的仓库中，不复制到 Nowcast。
