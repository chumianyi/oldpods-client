# 老豆荚 OldPods 客户端

基于 Flutter 的「老豆荚」（oldpods.cn）第三方 Android 客户端，采用 **Neumorphism（新拟态）** 设计风格，最低支持 **Android 7.0（API 24）**，通过 GitHub Actions 自动构建可安装的签名 Release APK。

## 功能特性

- **首页与浏览**：轮播 Banner、公告、分类导航、热门应用、猜你喜欢
- **应用列表**：多维度排序（最新 / 最热 / 评分 / 下载）、分类筛选、下拉刷新、上拉分页加载
- **应用详情**：截图查看器、评分、收藏、奖励领取、下载（含蓝奏云链接解析）、评论（分组渲染、发评论、删评论）
- **搜索**：应用搜索 + 用户搜索、搜索历史记录
- **账号体系**：登录 / 注册 / 找回密码、邮箱验证码、个人中心、资料编辑、头像上传
- **消息中心**：私信会话（实时轮询）、发消息、屏蔽/取消屏蔽、删除会话、系统消息
- **社区互动**：评论回复列表（@我的）、删除回复
- **积分商店**：商品列表、购买、我的背包、头像框更换
- **任务与排行**：每日签到、贡献排行榜、我的投稿
- **设置**：主题切换（跟随系统 / 浅色 / 深色）、设备过滤、检查更新、清除缓存、退出登录、注销账号
- **下载管理**：任务进度、取消、重试、安装、下载记录

## 技术栈

| 项目 | 说明 |
| --- | --- |
| 框架 | Flutter 3.24.5 / Dart 3 |
| 主题 | Neumorphism 新拟态（浅色 `#E0E5EC` / 深色 `#2A2E35`，凸起 / 按压 / 凹陷三种盒型） |
| 网络 | `http` 包 + 自建 ApiClient（Cookie 会话管理、统一错误处理、防御式 JSON 解析） |
| 状态 | 自写 AppState 单例 + AnimatedBuilder（零第三方状态管理依赖） |
| 存储 | `shared_preferences`（登录态、主题、搜索历史、下载记录） |
| 平台能力 | Kotlin MethodChannel 实现设备信息、APK 安装、浏览器打开、图片选择，无需额外插件 |
| 下载 | 自建 DownloadManager（流式下载 + 进度 + 取消 + 蓝奏云直链解析） |

## 构建

推送代码到 `main` 分支或手动触发 Workflow 即可自动构建：

1. 安装 Flutter 3.24.5 与 Java 17
2. 现场生成签名密钥库（`android/app/keystore/oldpods.jks`）
3. `flutter pub get`
4. `flutter build apk --release`
5. 上传 APK 构件（保留 90 天）

本地构建：

```bash
flutter pub get
flutter build apk --release
```

## 项目结构

```
lib/
├── main.dart                  # 入口
├── app.dart                   # MaterialApp 与路由表
├── models/models.dart         # 全部数据模型（防御式解析）
├── services/                  # API 客户端、接口封装、存储、下载、平台通道、蓝奏云解析
├── state/app_state.dart       # 全局状态
├── theme/neu_theme.dart       # Neumorphism 调色板与主题
├── widgets/                   # NeuBox / NeuButton / NeuTextField 等新拟态组件
└── screens/                   # 27 个功能页面
android/
└── app/src/main/kotlin/       # MainActivity（MethodChannel 平台实现）
```

## 声明

本项目为个人学习作品，基于老豆荚开放接口制作，与老豆荚官方无关。所有数据版权归原站点所有。
