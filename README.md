# RMC

## 简介

RMC是一款参考《Rotaeno》制作的音游。与传统的击打式音游不同，这款游戏通过旋转手机来让物件与判定点接触，从而实现音符的判定和得分的累积。

## 快速体验

### 下载

转到[release页面](https://github.com/chushi0/rmc/releases)下载最新安装包。目前支持Windows和Android两个平台。

> 理论上MacOS、Linux也可以支持，但我没有编译环境，有条件可以自行编译

### 操作方式

Desktop版：方向键控制旋转，Ctrl键加速，Shift键减速

Android版：转动手机控制旋转

### 谱面导入

RMC支持osu!谱面，可从[对应谱面网站](https://osu.ppy.sh/beatmapsets)上下载。

下载后，在游戏中选择“导入谱面”，会拉起系统文件选择器，选中刚刚下载的osz文件即可游玩。

## 项目结构及构建说明

项目由三部分组成：Godot、Rust和Android。要编译Desktop版，需要编译Godot和Rust部分。要编译Android版，需要编译Godot、Rust和Android三部分。

|模块|用途|
|:--|:--|
|Godot|游戏主要逻辑|
|Rust|包含osz文件解析、转谱和视频解码逻辑|
|Android|包含Android重力传感器、加速度计数据获取，以及拉起Android原生文件选择器|

### 环境配置

#### Godot

项目使用`Godot Engine v4.2.1.stable.official [b09f793f5]`版本，直接下载对应版本即可。

为了避免不同版本GDExtension的兼容问题，不建议选择过新或过旧的版本。（除非你有能力修改项目代码解决这一问题）

#### Rust

Rust的配置相对复杂，因为编译Rust部分需要依赖一个C++库。如果要同时编译Android版，你还需要下载Android的构建套件。

1. Rust要求电脑上至少安装一个C/c++编译器。你可以根据需要安装MSVC、GCC或CLANG。

2. 到[Rust网站](https://www.rust-lang.org/)根据说明安装Rustup、Rustc和Cargo

3. 安装[vcpkg](https://github.com/microsoft/vcpkg)，并根据其使用说明安装FFmpeg库

4. 如果你需要编译为Android版本，你还需要安装[Cargo ndk](https://github.com/bbqsrc/cargo-ndk)，并下载[Android NDK](https://developer.android.google.cn/studio/projects/install-ndk?hl=zh-cn#specific-version)。

#### Android

安装[Android Studio](https://developer.android.google.cn/studio)并按其说明配置。

由于众所周知的原因，使用Android Studio经常遇到下载依赖包失败的情况。

### 编译项目

#### Rust

根据需求在Rust文件夹中执行对应命令：

编译当前平台debug版
```sh
cargo build
```

编译当前平台release版
```sh
cargo build --release
```

编译Android平台release版
```sh
cargo ndk -t arm64-v8a build --release
```

通常而言，Rust的错误提示会比较完善，错误提示中也包含了对应的修改意见。如果遇到问题，可以参考错误提示进行修正。

编译后，在target目录会生成对应平台的动态链接库文件，并由Godot加载。

#### Android

通过Android Studio打开Android文件夹中的两个项目，执行gradle的`build`命令进行编译。

编译完成后，需要将`/Android/<Project>/plugin/demo/addons/`文件夹中的内容复制到`/Godot/addons/`的对应文件夹中。

#### Godot

在以上两项都编译完成后，才能在Godot中运行、导出项目。
