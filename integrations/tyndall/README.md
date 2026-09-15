# Tyndall integration snapshot

此目录保存首次集成的源文件快照，保持与 Tyndall 根目录相同的相对路径。
依赖宿主项目现有的 Astro、Vercel adapter、Supabase client、zod、别名配置和样式。
不是独立可运行的网站或通用后端包。

- `/api/presence`：公开 GET 与密钥保护的 POST。
- `supabase-nowcast-schema.sql`：一次性迁移，单独的新表，不修改 legacy 表。
- `NowStatus.astro`：20 秒轮询、双状态展示、过期清理、中英文和本地显式 fixture。
- `check-presence.mjs`：在宿主 Tyndall 根目录运行规则检查。

该 API 复用宿主环境变量 `PUBLIC_SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`、`NOW_PLAYING_SECRET`。
首次 Nowcast 上报前可以回退至已有 `/api/now-playing`；其实现不在本快照中。
完整接入步骤与验证状态见根目录 README 和 DEVELOPMENT。
