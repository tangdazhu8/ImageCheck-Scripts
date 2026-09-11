# 镜像点检脚本（scripts-v1.0）

面向客制化 Windows 镜像的出厂/交付点检。用 Windows 自带的 PowerShell 5.1 读取系统当前状态，与各脚本顶部的预期值比对，输出 `PASS` / `FAIL` / `MANUAL` / `SKIP`。

---

## 目录结构

```
D:\scripts-v1.0\
  README.md
  check_all.ps1              命令行总控（按文件名排序执行 checks\）
  common.ps1                 共用函数
  checks\
    01_language_packs.ps1    共 65 项，文件名 {两位编号}_{英文简述}.ps1
    ...
    65_device_manager.ps1
  screenshots\               截图类脚本写入此处（运行后生成）
```

---

## 使用方法

在 `D:\scripts-v1.0` 下：

```powershell
# 全部点检
.\check_all.ps1

# 只跑某一编号
.\check_all.ps1 -CheckNo 16

# 直接跑单个脚本
powershell -NoProfile -File .\checks\16_password_min_length.ps1
```

每条脚本向标准输出打印一行 JSON，例如：

```json
{"no":16,"name":"密码最小长度","status":"PASS","current":"Minimum password length=6","expected":"Minimum password length >= 6"}
```

`check_all.ps1`：有 `FAIL` 则退出码为 `1`，否则为 `0`。`MANUAL` 不计失败。

---

## 结果含义

| 状态 | 含义 | 建议 |
|------|------|------|
| PASS | 自动判定通过 | 无需操作 |
| FAIL | 与预期不符或脚本出错 | 对照「当前值 / 预期值」处理镜像 |
| MANUAL | 需看截图或现场 | 人工确认 |
| SKIP | 跳过 | 查看 current 说明原因 |

默认预期值在各 `checks\NN_xxx.ps1` 顶部的 `$expectedXxx`（或注释）。改默认标准请改脚本。

---

## 环境约束

点检以观察客制化系统为准，除明确允许的项外不改系统：

- 脚本只**读取**注册表做比对，不写入 `HKLM` / `HKCU`
- 不改 BCD、不装驱动
- **50 / 51**：没有 `newuser` 时会创建该用户（密码 `123456`），属检查步骤
- 截图写入本目录 `screenshots\`
- 设置页展开用 UI Automation 按名称 `Expand()`，跳过带 Toggle 的开关；避免 `Tab`/`Enter` 误拨旁边项

---

## 共用函数（common.ps1）

| 函数 | 作用 |
|------|------|
| `Write-CheckResult` | 输出一行压缩 JSON，供总控解析 |
| `Get-RegistryValue` | 读注册表，不存在则 `$null` |
| `Get-PowerSettingValue` | 解析 `powercfg /query`（兼容中英文冒号） |
| `Expand-SettingsExpander` | 在「设置」窗口按名称展开 expander，跳过 Toggle 开关 |
| `Restore-OriginalEncoding` / `Set-Utf8Encoding` | 调用 `bcdedit`、`dism`、`netsh` 等前恢复系统编码 |

另定义 `Native.Win32`（FindWindow、SetForegroundWindow 等）。含中文的 `.ps1` 须为 **UTF-8 带 BOM**。

---

## 如何增删点检项

在本目录 `checks\` 增删即可。`check_all.ps1` 按文件名排序执行全部 `*.ps1`。

**新增**

1. 复制相近脚本（注册表 / 驱动版本 / 截图）
2. 文件名用下一个空闲编号，两位数字开头
3. 修改顶部编号、名称、预期值，点源 `common.ps1`，最后：

```powershell
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
```

**删除**：从 `checks` 去掉对应 `.ps1`。

---

## 点检项一览

名称与脚本内 `$checkName` 一致。预期值以各脚本顶部变量为准，换镜像时改那里。

| 编号 | 名称 | 判定 | 说明 |
|------|------|------|------|
| 01 | 语言包 | 自动 | 须含 en-us、zh-cn、fr-fr、de-de、es-es、ja-jp、ru-ru、zh-tw、pt-pt、ar-sa |
| 02 | 电源设置 | 自动 | 磁盘/睡眠/休眠超时 0；显示器 600 秒 |
| 03 | Touch Keyboard | 截图 MANUAL | `ms-settings:typing`；按名称展开「显示更多设置」 |
| 04 | BCD fix mode | 自动 | recoveryenabled=No，bootstatuspolicy=IgnoreAllFailures；无管理员则 MANUAL |
| 05 | Time zone | 截图 MANUAL | `ms-settings:dateandtime` |
| 06 | UAC | 截图 | EnableLUA=0 → MANUAL；非 0 → FAIL；只关本次 UAC 窗口 |
| 07 | Miracast | 截图 MANUAL | `ms-settings:project` |
| 08 | HID设备电源节能 | 自动 | 已连接 HID 的电源节能应关闭 |
| 09 | USB设备电源节能 | 自动 | 已连接 USB 的电源节能应关闭 |
| 10 | 任务栏Touch keyboard | 自动 | TabletTip `TipbandDesiredVisibility`=1 |
| 11 | Taskbar icons | 截图 MANUAL | `ms-settings:taskbar` |
| 12 | 快速启动功能 | 截图 MANUAL | 电源选项「电源按钮」页；用 Shell.Application 关窗口 |
| 13 | IgnoreSinkScdcRrCapability | 自动 | 显示类 0000 下该值为 1 |
| 14 | CVE-2013-3900 | 自动 | EnableCertPaddingCheck=1 |
| 15 | Hidden server | 自动 | `net config server` 显示 Hidden=Yes |
| 16 | 密码最小长度 | 自动 | ≥ 6 |
| 17 | 账户锁定策略 | 自动 | 阈值 5，锁定/复位 10 分钟 |
| 18 | SMB数字签名 | 自动 | RequireSecuritySignature 与 EnableSecuritySignature 均为 1 |
| 19 | 默认共享和IPC | 自动 | RestrictAnonymous=1，AutoShareServer/Wks=0 |
| 20 | LM Hashing | 自动 | LmCompatibilityLevel=5，NtlmMinClientSec 含 0x20000000 |
| 21 | ICMP Timestamp | 自动 | 入站防火墙规则阻止 ICMPv4 时间戳 |
| 22 | NetBIOS | 自动 | 接口 NetbiosOptions=2（禁用） |
| 23 | USB选择性暂停 | 自动 | 电源方案 USB 选择性暂停=0 |
| 24 | 无线设备节能 | 自动 | AC 无线节能模式=0（最高性能） |
| 25 | TCP Timestamps | 自动 | `netsh` 显示 disabled |
| 26 | IdeaShare快捷方式 | 自动 | 公用桌面存在 IdeaShare OPS Server Download.url |
| 27 | WMIC功能 | 自动 | 可选功能 WMIC 已启用 |
| 28 | OS Build | 自动 | 26200.8737 |
| 29 | Defender版本 | 自动 | Platform / Engine / Signatures 与脚本顶部一致 |
| 30 | Edge版本 | 自动 | Edge 与 WebView2 均为 150.0.4078.83 |
| 31 | .NET Framework | 自动 | 已安装 KB5100998 |
| 32 | Chipset驱动 | 自动 | 10.1.47.12 |
| 33 | Serial IO驱动 | 自动 | 30.100.2527.40 |
| 34 | ME驱动 | 自动 | 2540.8.7.0 |
| 35 | VGA驱动 | 自动 | 32.0.101.8425 |
| 36 | ISST驱动 | 自动 | 20.40.12350.3 |
| 37 | Audio驱动 | 自动 | 6.0.9937.1 |
| 38 | RLAN驱动 | 自动 | 10.79.50.1003 |
| 39 | WLAN驱动 | 自动 | 23.160.0.4 |
| 40 | BT驱动 | 自动 | 1.1044.0.556 |
| 41 | NPU驱动 | 自动 | 32.0.100.4404 |
| 42 | PMT驱动 | 自动 | 3.1.2.6 |
| 43 | Realtek USB LAN驱动 | 自动 | 11.15.327.2024 |
| 44 | Realtek USB WLAN驱动 | 自动 | 1030.52.731.2025 |
| 45 | USB RNDIS驱动 | 自动 | 10.0.26100.1 |
| 46 | 安装日志 | 自动 | `C:\installation.log` 含 OS V2.0.1.5、日期 20260814 |
| 47 | IdeaUI预装 | 自动 | DevChanSvc 1.1.26.0，IdeaUI_OPS 25.1.0.48 |
| 48 | IdeaShareKey | 自动 | `C:\Program Files\IdeaUI\IdeaShareKey` 存在 |
| 49 | 三指四指触摸 | 截图 MANUAL | `ms-settings:devices-touch` |
| 50 | 多用户软键盘 | MANUAL | 可创建 newuser；人工确认多用户软键盘 |
| 51 | 多用户软键盘按钮 | MANUAL | 同上，确认任务栏按钮 |
| 52 | 初始化日志 | 自动 | `%SystemRoot%\System32\log.log` 中恰好 4 条 `status: Success` 且无失败 |
| 53 | 系统版本 | 自动 | Windows 11 Enterprise 25H2 |
| 54 | 系统初始化提示 | MANUAL | 人工确认安装后初始化界面 |
| 55 | 系统加密 | 截图 MANUAL | `ms-settings:deviceencryption` |
| 56 | 目标功能更新版本 | 自动 | TargetReleaseVersion=25H2，ProductVersion=Windows 11 |
| 57 | 禁用预览版本推送 | 自动 | DeferFeatureUpdates=1，DeferPeriod=0，无暂停时间 |
| 58 | 自动更新配置 | 自动 | AUOptions=3 等（见脚本顶部多项） |
| 59 | 优化配置脚本 | MANUAL | 人工确认优化脚本执行后是否重启 |
| 60 | ideaUI启动 | MANUAL | 人工确认重启，并记录相关耗时 |
| 61 | 关闭Hyper-V | 自动 | Hyper-V 相关功能为 Disabled |
| 62 | TCP端口排除 | 自动 | 排除端口含 1444、4999 |
| 63 | 静默安装命令 | 自动 | `%SystemDrive%\recovery\oem\scanstate.bat` 第 33 行与脚本预期一致 |
| 64 | 禁用边缘滑动 | 截图 MANUAL | `ms-settings:devices-touch`；按名称展开「边缘手势」，不用 Tab/Enter |
| 65 | 设备管理器黄标 | 截图 MANUAL | 打开设备管理器并展开，人工看有无黄标 |

---

## 编写新脚本时注意

1. 点源 `common.ps1`，最后用 `Write-CheckResult` 输出一行 JSON
2. 含中文的 `.ps1` 保存为 **UTF-8 带 BOM**，否则 Windows PowerShell 5.1 可能解析失败
3. 截图类：尽量只关闭本脚本打开的窗口；不要按进程名结束全部 `dllhost`
4. 设置页用 `Expand-SettingsExpander -NameHints`，不要用 `Tab`/`Enter` 当主路径
5. 能读注册表的不要靠点 UI 判定；不要在点检里写系统策略（50/51 建测试用户除外）

---

## 常见问题

**中文乱码或脚本语法错误**  
检查该 `.ps1` 是否为 UTF-8 BOM。

**bcdedit / dism / netsh 输出解析失败**  
先 `Restore-OriginalEncoding` 再调外部命令，结束后 `Set-Utf8Encoding`。
