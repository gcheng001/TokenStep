# TokenStep 0.2.4 主题皮肤包

开发分支：`codex/tokenstep-0.2.4`。开发基线为 0.2.3 的横向浮窗与 Voyage 全界面实现；0.2.3 尚未独立提交，因此本版本保留其工作区改动并在其上演进。

## 产品结构

- `经典`：保留青绿、海蓝、紫藤、琥珀、石墨五种原版配色；
- `奥德赛`：包含导演剪辑、爱琴海冷雾、特洛伊火海、灰烬神像四个视觉篇章；
- `导演剪辑`：菜单栏浮窗与 Token Island 使用冷雾头盔，Today 与分享/更新使用木马火线，历史、隐私和设置使用灰烬大理石；
- 切回经典时记住上次经典配色；切回奥德赛时记住上次视觉篇章；
- 0.2.3 已保存的 `.voyage` 设置会自动解释为奥德赛主题包的导演剪辑，不丢失其他设置。

## 视觉规则

- Token 用量、圆环与额度使用骨金、冷金、余烬橙或石灰金，不使用绿色作为奥德赛主用量色；
- 绿色只保留给同步成功、省电策略等明确的成功状态；
- V2 弓箭阶梯 Logo 保持几何结构，按篇章改变周围材质和字标；
- 菜单栏浮层使用原创 AI 生成的无字电影背景板；其他界面继续使用 SwiftUI Canvas 原创矢量母题，不打包电影海报、演员肖像或片方素材；
- 奥德赛浮层改为约 `1.52:1` 的三段式电影构图：今日用量、Agent 用量、订阅额度；Agent 消耗榜收为底部信息带，不再形成第五列；
- 经典主题继续沿用原来的横向数据布局；两套主题共用真实数据组件，不改变统计口径。

## 关键实现

- `Support/Theme.swift`：主题包、四篇章、配色与运行时选择；
- `Models/UsageModels.swift`：持久化 `classic_theme` 与 `odyssey_chapter`；
- `Stores/AppState.swift`：主题包、经典配色和奥德赛篇章切换；
- `Views/VoyageSkin.swift`：头盔骨节冠、木马、灰烬神像、火星、冷雾与希腊回纹；
- `TokenUsageMenuApp/assets/odyssey/`：爱琴海、特洛伊与灰烬三张无字浮层背景板；导演剪辑的浮层复用爱琴海背景；
- `Views/Settings/SettingsGeneralPane.swift`：主题皮肤包与视觉篇章选择器；
- 横向浮窗、主窗、历史、隐私、设置、分享、更新和 Token Island 均接入界面角色。

## 验收

```bash
cd TokenStepSwift
swift test
cd ..
./script/check_localization.py
./script/render_odyssey_theme_pack.sh docs/validation/v0.2.4-odyssey-theme-pack
TOKENSTEP_VERSION=0.2.4 ./script/build_swiftui_and_run.sh --no-launch
```

视觉验收会输出经典主题和四个奥德赛篇章，每套包含：横向浮窗、Today、历史、隐私、设置三页与全页、更新窗口、Token Island 折叠/展开、今日分享卡和昨日节奏卡。浮层专项脚本还会同时输出含排行榜与不含排行榜两种状态。

当前实现和静态快照验收不等于已签名、公证或发布。公开发布仍需运行 `package_release.sh --notarize` 并验证 DMG。
