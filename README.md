<p align="center">
    <img src="https://raw.githubusercontent.com/xfangfang/wiliwili/refs/heads/yoga/resources/svg/cn.xfangfang.wiliwili.svg" alt="logo" height="128" width="128"/>
</p>
<p align="center">
  <a href="https://github.com/xfangfang/wiliwili">wiliwili</a> 的 UWP 移植版本，适用于 Xbox 主机与 Windows 10+
</p>
<p align="center">
<b><a href="#关于">关于</a></b>
|
<b><a href="#安装">安装</a></b>
|
<b><a href="#开发">开发</a></b>
</p>

- - -

[![build](https://github.com/thedavidweng/wiliwili-uwp/actions/workflows/build-x64.yml/badge.svg)](https://github.com/thedavidweng/wiliwili-uwp/actions/workflows/build-x64.yml)
![Xbox](https://img.shields.io/badge/-Xbox-107C10?style=flat&logo=Xbox)
![Windows](https://img.shields.io/badge/-Windows%2010+-0078D6?style=flat&logo=Windows)

<br>

# 关于

本项目是 [wiliwili](https://github.com/xfangfang/wiliwili)（一个第三方 B 站客户端）的 UWP 移植版本，主要面向 **Xbox 主机**用户。

wiliwili 的功能与特性请参考 [上游项目](https://github.com/xfangfang/wiliwili)，此处不再赘述。

### 来龙去脉

UWP 版本由 [ikas-mc](https://github.com/ikas-mc) 开发，移植了 mpv 播放器至 UWP 平台，并完成了 borealis 框架的 WinRT 适配。项目最初托管于 [ikas-mc/wiliwili-uwp-poc](https://github.com/ikas-mc/wiliwili-uwp-poc)，后上架微软商店供 Xbox 用户下载（详见 [xfangfang/wiliwili#468](https://github.com/xfangfang/wiliwili/issues/468)）。

2026 年 1 月，ikas-mc [表示将不再维护 UWP 版本](https://github.com/xfangfang/wiliwili/issues/468#issuecomment-3817713715)。本仓库目前跟踪上游 wiliwili 的版本更新。

### 与上游的关系

本项目不直接提交 wiliwili 与 borealis 源码。构建时拉取已固定提交的 UWP/WinRT 适配分支，并通过本仓库的 CMake 配置生成 UWP 包。

<br>

# 安装

### Xbox

在主机商店搜索 **Wiliwili** 即可下载：[微软商店页面](https://apps.microsoft.com/detail/9PJQP559TZC1)

> 由于审核原因，新版本可能无法及时上架商店。如需加入测试组获取最新版本，请关注 [xfangfang/wiliwili#468](https://github.com/xfangfang/wiliwili/issues/468) 中的说明。

### Windows

从 [GitHub Actions](https://github.com/thedavidweng/wiliwili-uwp/actions/workflows/build-x64.yml) 下载最新构建产物（需登录 GitHub）。

<br>

# 开发

### 依赖

- Visual Studio 2022 或 2026
- [vcpkg](https://github.com/microsoft/vcpkg)
- CMake 3.20+

### 构建

```powershell
# 克隆本仓库
git clone https://github.com/thedavidweng/wiliwili-uwp.git
cd wiliwili-uwp

# 运行构建脚本（自动拉取依赖并编译）
.\build-ci.ps1
```

### 项目结构

```
wiliwili-uwp/
├── CMakeLists.txt          # 顶层 CMake（UWP 工具链配置）
├── wiliwili.cmake          # wiliwili 构建配置（版本、源文件、编译选项）
├── borealis.cmake          # borealis 构建配置（D3D11、WinRT 平台）
├── build-ci.ps1            # 构建脚本（拉取固定提交的依赖 + 编译）
├── wiliwili/               # wiliwili 源码（gitignored，构建时自动拉取）
├── borealis/               # borealis 框架（gitignored，构建时自动拉取）
├── libs/mpv/               # mpv UWP 预编译库
└── wiliwili-uwp/           # UWP 应用清单与资源
```

<br>

# 致谢

- [xfangfang](https://github.com/xfangfang) — wiliwili 作者
- [ikas-mc](https://github.com/ikas-mc) — UWP 版本原作者，完成了 mpv 的 UWP 移植与 borealis WinRT 适配
