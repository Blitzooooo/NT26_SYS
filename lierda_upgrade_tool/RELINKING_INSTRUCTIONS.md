# Qt库重新链接说明

本软件使用了Qt库，该库遵循GNU Lesser General Public License v3 (LGPLv3)协议。根据LGPLv3的要求，用户有权替换Qt库的新版本并重新链接应用程序。

## 可替换的Qt库文件

在本软件的安装目录_internal\PySide6、_internal下，您可以找到以下可替换的Qt库文件：

### 核心库文件
- Qt6Core.dll
- Qt6Gui.dll
- Qt6Widgets.dll
- Qt6Network.dll
- Qt6SerialPort.dll
- Qt6Svg.dll
- Qt6OpenGL.dll
- Qt6Pdf.dll
- Qt6Qml.dll
- Qt6QmlMeta.dll
- Qt6QmlModels.dll
- Qt6QmlWorkerScript.dll
- Qt6Quick.dll
- Qt6VirtualKeyboard.dll

### Python绑定文件
- pyside6.abi3.dll
- QtCore.pyd
- QtGui.pyd
- QtNetwork.pyd
- QtWidgets.pyd

### 运行时依赖
- MSVCP140.dll
- MSVCP140_1.dll
- MSVCP140_2.dll
- VCRUNTIME140.dll
- VCRUNTIME140_1.dll
- opengl32sw.dll

## 如何获取新的Qt库文件

1. 从Qt官方下载页面获取：https://www.qt.io/download
2. 通过PySide6安装包获取：pip install PySide6
3. 从Qt源代码编译生成

## 替换步骤

1. 备份原版库文件
2. 将新版本的库文件复制到_internal\PySide6\目录下，覆盖原有文件
3. 运行lierda_upgrade_tool.exe测试应用程序是否正常工作

## 注意事项

1. 新的库文件必须与原版本兼容
2. 替换后请全面测试应用程序功能
3. 如果出现兼容性问题，请恢复使用原始库文件

## 获取源代码

根据LGPLv3协议要求，您可以从以下途径获取Qt库的源代码：
- Qt官方源代码仓库：https://code.qt.io/
- PySide6源代码：https://github.com/qtproject/qt-pyside-setup

如果您需要我们提供Qt库的源代码，请联系我们的技术支持团队。