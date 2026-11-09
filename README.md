# YT Lite — iOS 14 可安装 IPA 源码

一个最小化的原生壳：点开图标直接进入官方移动网页 `m.youtube.com`，首页、Shorts、订阅、媒体库、搜索、频道、播放列表、评论、登录与会员权益都是官方自己的功能。部署目标 iOS 14.0，产出**未签名 IPA**，供 TrollStore / 自签安装。

## 文件

| 文件 | 作用 |
|---|---|
| `App.swift` | 单文件源码：`@main` + WKWebView 壳，完整 Safari UA、内联/画中画播放、持久化登录、下拉刷新、进度条、粘贴链接、桌面 UA 排障、拦截 App Store 跳转 |
| `Info.plist` | Bundle 配置，bundle id `com.ytlite.ios14`，最低 iOS 14.0 |
| `build.sh` | **不需要 .xcodeproj**，直接用 `swiftc` 交叉编译 arm64 并组装 `.app` + IPA |
| `icon.b64` | 180×180 应用图标（base64，构建时解码为 `Icon.png`） |
| `.github/workflows/build-ipa.yml` | 免费 macOS 云端编译，产出 artifact + Release + 仓库内 IPA 镜像 |

## 方式 A：云端出 IPA（推荐，不需要 Mac）

1. 在 GitHub 新建一个**公开空仓库**（例如 `ytlite-ios14`），不要勾选 README 初始化。
2. 把本目录全部文件上传上去，**保留 `.github/workflows/` 这一层路径**。
3. push 后 Actions 会自动运行 `Build unsigned IPA`；也可以到 Actions 页手动点 `Run workflow`。
4. 几分钟后在 **Releases** 下载 `YTLite-unsigned.ipa`；仓库根目录还会生成 `YTLite-unsigned.ipa.b64`（同样内容，文本形式）。

## 方式 B：自己有 Mac

```bash
cd YTLite-IPA
chmod +x build.sh
./build.sh          # 产出 YTLite-unsigned.ipa
```

只需要 Xcode 命令行工具，不需要开发者账号、不需要证书。

## 安装

- **TrollStore**（iOS 14.0–14.8.1 支持）：把 IPA 传到手机，用 TrollStore 打开即永久签名安装。
- **Sideloadly / AltStore**：用免费 Apple ID 重签安装，7 天续签一次。

## 说明

- 这是官方移动网页的完整功能，不是原生 App 的 100% 复刻：离线下载、后台播放、系统推送、上传不会有。
- 不含抓流、去广告、破解会员，也不含任何代理 / VPN / 网络穿透能力。能否访问 youtube.com 取决于设备自身网络，请在合规网络条件下使用。
- 部分视频被上传者禁止第三方页面嵌入，这时改用官方页面观看。
