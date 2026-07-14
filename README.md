# NCMEase

一个简单的 macOS 工具，用于将网易云音乐的 `.ncm` 文件转换为可播放的音频文件（通常为 MP3）。转换后的文件会保存在原 NCM 文件所在的文件夹中，并写入歌曲名称、歌手、专辑和封面等元数据。

## 使用方法

### 1. 安装

1. 前往 [Releases](https://github.com/Kgym-Hina/NCMEase/releases) 下载最新版本的 `NCMEase.app` 压缩包。
2. 解压后，将 `NCMEase.app` 拖入 macOS 的 `Applications`（应用程序）文件夹。
3. 在应用程序中运行一次 `NCMEase`，完成 `.ncm` 文件关联注册。首次运行完成后应用会自动退出，这是正常现象。

### 2. 转换 NCM 文件

完成首次运行后，直接双击任意网易云音乐 `.ncm` 文件即可自动转换。也可以一次选中多个 `.ncm` 文件后双击，NCMEase 会逐个处理。

转换完成后，MP3 文件会出现在原 NCM 文件所在的文件夹中：

```text
歌曲名称.ncm  ->  歌曲名称.mp3
```

如果 macOS 没有自动使用 NCMEase 打开文件，可以右键点击 NCM 文件，选择“打开方式”→“NCMEase”；也可以在“显示简介”→“打开方式”中选择 NCMEase，并点击“全部更改”。

## 系统要求

- macOS 14.0 或更高版本
- Apple Silicon 或 Intel Mac

## 从源码构建

1. 使用 Xcode 打开 `NCMEase.xcodeproj`。
2. 选择 `NCMEase` Scheme。
3. 选择 `My Mac` 作为运行目标并执行构建。
4. 在构建产物中找到 `NCMEase.app`，将它拖入 `Applications` 文件夹，然后按上面的安装步骤运行一次。

## 注意事项

- NCMEase 只处理 `.ncm` 文件，不会修改原始 NCM 文件。
- 输出文件与原文件同名；如果同名文件已存在，系统会按应用当前的文件写入行为处理。
- 请确保你拥有并遵守相关音频文件的使用权。此工具仅用于个人文件格式转换。

## License

当前仓库未声明开源许可证。未经作者许可，请不要将本项目用于商业分发或集成到其他产品中。
