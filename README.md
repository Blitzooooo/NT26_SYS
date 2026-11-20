# NT26_SYS

## 项目简介

本仓库是基于 Lierda Cat.1 OpenCPU SDK 的嵌入式开发工程集合，主要面向
NT26 系列蜂窝模组。工程包含 OpenCPU SDK、多个用户层示例应用、硬件开发板
Demo、AI/语音产品应用以及固件升级工具。

仓库当前主要内容：

```text
NT26_SYS/
├── CAT1.bis_OpenCPU/       OpenCPU SDK 和用户应用源码
├── lierda_upgrade_tool/    固件编译、打包和烧录相关工具资源
├── LierdaCommonUSBSetup... USB 驱动安装程序
└── README.md               项目说明
```

## OpenCPU 软件架构

`CAT1.bis_OpenCPU` 的代码可以理解为三层：

```text
用户层
  app、demo、NT26FxDx_OpenKit、CT4IT00YP00W_03、router 等应用
        ↓
系统层
  FreeRTOS、LIOT API、驱动、网络协议栈、OTA、TTS、第三方组件
        ↓
底包层
  针对具体模组和芯片的底包、启动代码、内存布局和底层库
```

- **底包层**：由 SDK 和模组型号决定，位于
  `CAT1.bis_OpenCPU/components/basePkg/`，一般不直接修改。
- **系统层**：提供 FreeRTOS、LIOT API、外设驱动、网络、文件系统、OTA 和
  第三方库等能力。
- **用户层**：开发者编写的应用代码，主要位于
  `CAT1.bis_OpenCPU/examples/`。用户程序通常从
  `void user_main(void)` 进入。

用户层的底层运行环境是 **FreeRTOS + LIOT API**。常见调用包括：

- `liot_rtos_task_create()`：创建任务；
- `liot_rtos_task_sleep_ms()`：任务延时；
- `liot_gpio2`、`liot_spi`、`liot_i2c`、`liot_uart2`：外设操作；
- `liot_datacall`、`liot_http`、Socket、MQTT、WebSocket：网络通信；
- `liot_fs_api`、Flash、NVM：数据和文件存储。

## examples 工程总览

工程入口由 `CAT1.bis_OpenCPU/examples/Makefile` 根据 `PROJECT` 参数选择，
一次构建通常只选择一个用户工程。

### app：空白起始工程

目录：[`CAT1.bis_OpenCPU/examples/app`](CAT1.bis_OpenCPU/examples/app)

`app` 是最小用户工程，入口为
[`src/user_main.c`](CAT1.bis_OpenCPU/examples/app/src/user_main.c)，默认只
打印堆内存信息。适合从零开发自己的产品，自己设计任务、模块、消息队列和
业务流程。

### demo：API 和外设功能示例

目录：[`CAT1.bis_OpenCPU/examples/demo`](CAT1.bis_OpenCPU/examples/demo)

`demo` 是 LIOT API 和常见功能的参考集合，覆盖：

- ADC、GPIO、UART、I2C、SPI、PWM、RTC、定时器和休眠唤醒；
- LCD、触摸屏、摄像头、JPEG、键盘和 WS2812B；
- 文件系统、Flash、外部 Flash、NVM 和 ZIP；
- 数据拨号、SIM、GNSS、LBS、短信、VoLTE 和 Wi-Fi 扫描；
- HTTP、HTTP FOTA、FTP、Socket、SSL、WebSocket、MQTT 和 Ping；
- 声音播放、PWM 音频、TTS 以及 LVGL 图形界面。

入口为 [`src/0demo_main.c`](CAT1.bis_OpenCPU/examples/demo/src/0demo_main.c)。
每项功能由 `examples/demo/config` 中的 `EXDEMO_*_EN` 开关控制：

```makefile
EXDEMO_HTTP_EN=y
EXDEMO_MQTT_ALI_EN=y
EXDEMO_WS2812B_EN=y
```

开启后，`Makefile` 会添加对应宏并把示例源码加入编译。关闭的功能不会参与
编译，因此可以用来隔离硬件和功能模块。

Demo 代码主要用于展示 API 调用方式，不一定是完整产品代码。使用时需要重新
确认硬件引脚、外设端口、电源控制、资源占用、内存检查、超时处理和错误处理。
例如 [`demo_ws2812b.c`](CAT1.bis_OpenCPU/examples/demo/src/demo_ws2812b.c)
演示了通过 SPI 编码和发送 WS2812B 数据，但正式应用仍需确认 SPI、供电 GPIO、
LED 数量以及其他模块是否占用相同资源。

### NT26FxDx_OpenKit：开发板硬件验证和 AI Demo

目录：
[`CAT1.bis_OpenCPU/examples/NT26FxDx_OpenKit`](CAT1.bis_OpenCPU/examples/NT26FxDx_OpenKit)

该工程面向 NT26FxDx 开发板，配置支持：

- `BUILD_MODE=demo`：开发板硬件验证或特定功能 Demo；
- `BUILD_MODE=app`：使用工程中的应用代码。

Demo 模式可以通过 `DEMO_NAME` 选择：

- `hardware`：按键、LCD、摄像头、触摸屏、声音和 WS2812B 验证；
- `demo_zhongyi_ai`：通过蜂窝网络、WebSocket、Opus 和 ES8311 实现 AI 语音
  对话；
- `demo_3a`：音频 3A 回环处理；
- `demo_watch`：手表类 AI 应用示例。

该工程更贴近具体开发板。启用功能前应确认硬件连线，并注意 I2C、SPI 和
GPIO 复用冲突。

### NT26FxDx_OpenKit_TiRTC：产品级实时语音应用

目录：
[`CAT1.bis_OpenCPU/examples/NT26FxDx_OpenKit_TiRTC`](CAT1.bis_OpenCPU/examples/NT26FxDx_OpenKit_TiRTC)

该工程不是单一 API Demo，而是面向 NT26F6D0 开发板的产品应用，包含：

- 三键 OLED 用户界面；
- LTE 联网、网络授时和设备绑定；
- AI 语音聊天；
- 微信语音通话；
- 设备间语音通话；
- 平台 LIVE 音频对讲；
- 共享音频和编解码资源。

工程按应用启动、核心生命周期、网络服务、业务功能、媒体和 UI 分层，
适合参考复杂产品如何组织多个功能、管理共享音频资源、处理连接状态和
进行错误恢复。

该工程的 `tirtc/sdk` 包含 TiRTC 头文件和预编译静态库。相关 SDK 材料有
单独的授权边界，使用和再分发时需要遵守对应授权，不应把它们视为普通应用
源码的一部分。

### CT4IT00YP00W_03：AI 硬件产品应用

目录：
[`CAT1.bis_OpenCPU/examples/CT4IT00YP00W_03`](CAT1.bis_OpenCPU/examples/CT4IT00YP00W_03)

该工程面向 CT4IT00YP00W-03A 硬件，包含：

- GX8006 音频芯片、麦克风和扬声器；
- WS2812B LED；
- 电池检测和充电控制；
- LDO 电源、开关机按键和网络；
- 定位；
- WebSocket AI 和语音交互。

它在 FreeRTOS/LIOT 任务之外，还使用了事件、Job、Policy 和软件定时器框架。
典型流程如下：

```text
按键或音频唤醒
    → 录音
    → 网络/AI 连接
    → 等待回复
    → 播放音频
    → 返回空闲状态
```

独立、长期运行的功能（例如传感器采集或后台监测）可以使用 FreeRTOS Task；
具有明确状态切换、事件响应和资源互斥要求的功能，更适合实现为 Job。新增
Job 时通常需要增加事件或 Job 类型、实现 Job 回调、注册 Job，并同步更新
全局 Policy。

### router：Cat.1 蜂窝网络路由器

目录：
[`CAT1.bis_OpenCPU/examples/router`](CAT1.bis_OpenCPU/examples/router)

`router` 是完整的蜂窝网络网关示例，以蜂窝数据作为 WAN、以 CH390 SPI
以太网作为 LAN，提供：

- ARP 代理、DHCP、NAT/NAPT 和端口映射；
- LAN 口和网络状态指示灯；
- 配置持久化；
- 可选 Web 管理页面；
- 登录认证、网络配置、系统维护和本地固件升级。

它适合开发网络网关或路由器，不适合作为普通传感器、外设控制或 AI App
的通用起始工程。

## 如何选择工程

| 需求 | 建议工程 |
| --- | --- |
| 从零编写普通产品 | `app` |
| 查询某个 LIOT API 或外设用法 | `demo` |
| 验证 NT26FxDx 开发板硬件 | `NT26FxDx_OpenKit` |
| 开发 AI、通话或实时音频产品 | `NT26FxDx_OpenKit_TiRTC` |
| 开发 CT4IT00YP00W-03A AI 硬件 | `CT4IT00YP00W_03` |
| 开发蜂窝网络路由器 | `router` |

## 多功能应用的推荐组织方式

不要把所有 Demo 文件直接堆到一个 `user_main.c` 中。建议按职责拆分：

```text
my_product/
├── config                 编译开关和产品配置
├── inc/                   公共头文件
├── src/
│   ├── user_main.c        启动和任务组合
│   ├── tasks/             独立的 FreeRTOS 任务
│   ├── drivers/           产品硬件封装
│   ├── services/          网络、存储、协议等业务
│   └── jobs/              需要事件驱动的状态机
└── Makefile               工程构建规则
```

推荐按以下原则设计：

1. 独立周期功能使用 FreeRTOS Task；
2. 有明确状态切换、事件响应和资源互斥的流程使用 Job/Event；
3. 通过队列、事件或消息传递数据，避免多个任务直接修改同一份状态；
4. 每个硬件资源明确唯一的拥有者，避免重复初始化 SPI、I2C、音频或 GPIO；
5. 对内存分配、外设初始化、网络连接和任务创建检查返回值；
6. 为网络和硬件操作增加超时、失败重试和恢复路径；
7. 只在唯一的 `user_main()` 中完成应用级任务组合。

## Demo 代码的复用方式

不需要删除 `examples/demo`。它可以长期保留，作为 API 和硬件用法参考。
推荐流程是：

1. 确认模组型号、开发板和硬件引脚；
2. 在 `demo` 中找到对应 API 示例；
3. 检查 SPI、I2C、UART、GPIO、音频等资源是否已被其他模块占用；
4. 将示例逻辑封装为自己的 Driver、Service、Task 或 Job；
5. 加入产品级错误处理、超时处理、内存检查和资源释放；
6. 在自己的工程中编译、烧录并通过串口日志验证。

一次构建只选择一个 `PROJECT`，不应把 `app`、`demo` 和其他完整产品工程
同时加入同一个固件，否则可能出现多个 `user_main()` 或硬件资源冲突。

## 常用构建命令

在 `CAT1.bis_OpenCPU` 目录下执行：

```bash
# 默认工程
make all PROJECT=app MODEM=NT26F6D0 MODEMPKG=F6D_A

# 编译 API Demo
make all PROJECT=demo MODEM=NT26F6D0 MODEMPKG=F6D_A

# 编译 CT4IT 产品工程
make all PROJECT=CT4IT00YP00W_03 MODEM=NT26F6D0 MODEMPKG=F6D_A

# Windows 环境可使用对应的 build.bat
build.bat all PROJECT=demo MODEM=NT26F6D0 MODEMPKG=F6D_A
```

编译产物通常位于 `CAT1.bis_OpenCPU/gccout/<工程名>/`，包括应用包和底包
合包。烧录前必须确认工程、模组型号、底包版本和实际硬件匹配。