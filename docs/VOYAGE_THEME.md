# TokenStep Voyage 主题

> 本文记录 0.2.3 的历史实现。0.2.4 已升级为可切换主题皮肤包，见 [ODYSSEY_THEME_PACK_0.2.4.md](ODYSSEY_THEME_PACK_0.2.4.md)。

开发基线：`v0.2.2` / `7338fcb`。目标版本：`0.2.3`。

## 已接入

- 正式 App Icon：V2 `Artisan Recurve`；
- 新增 `TokenStepTheme.voyage`，不覆盖青绿、海蓝、紫藤、琥珀和石墨；新安装与恢复默认使用 Voyage；0.2.2 升级到 0.2.3 时会一次性切换到 Voyage，之后仍尊重用户主动选择；
- 黑盘 `#0B0C0B`、碳黑表面 `#171814`、旧青铜 `#B77A44`、暖黄铜 `#D0A36A`、象牙白 `#E7DDC8`；
- 同步成功使用独立绿色 `#4FA77B`，Token 用量与额度不使用绿色；
- 横版浮窗启用弓弧进度、铆钉列分隔、航线水印和低对比头盔浮雕；
- 主窗口的今日、历史、隐私页完成黑盘、青铜描边、卡片铆钉和武器/航线浮雕；
- 设置的数据源、额度、通用页统一为 Voyage 控件体系；
- Token Island 折叠/展开态、更新窗口、今日分享卡和昨日节奏卡完成换肤；
- 全局品牌锁定为 V2 弓箭图标 + `VOYAGE EDITION` 字标；
- 16–22px 菜单栏仍保留动态用量圆环，不牺牲数据功能。

## 关键文件

- `TokenStepSwift/Sources/TokenStepSwift/Support/Theme.swift`
- `TokenStepSwift/Sources/TokenStepSwift/Support/Formatters.swift`
- `TokenStepSwift/Sources/TokenStepSwift/Views/VoyageSkin.swift`
- `TokenStepSwift/Sources/TokenStepSwift/Views/PopoverPanelView.swift`
- `TokenStepSwift/Sources/TokenStepSwift/Views/Popover/`
- `TokenStepSwift/Sources/TokenStepSwift/Views/Settings/`
- `TokenStepSwift/Sources/TokenStepSwift/Views/Share/`
- `TokenStepSwift/Sources/TokenStepSwift/Views/TokenIslandView.swift`
- `TokenUsageMenuApp/assets/TokenStepIcon.*`

## 验证

```bash
./script/render_popover_panel.sh docs/validation/v0.2.3-popover-voyage
./script/render_today_dashboard.sh docs/validation/v0.2.3-today-voyage
./script/render_voyage_interfaces.sh docs/validation/v0.2.3-voyage-interfaces
TOKENSTEP_VERSION=0.2.3 ./script/build_swiftui_and_run.sh --no-launch
```

当前完成的是本地实现、逐屏静态渲染与生产构建验收，不等于已安装、签名、公证或发布。
