# 镜像点检（Image Checklist Audit）

面向客制化 Windows 镜像的出厂/交付点检工具。用 PowerShell 读取系统当前状态，与脚本内（或界面 catalog 中）的预期值比对，输出 `PASS` / `FAIL` / `MANUAL` / `SKIP`。

图形界面与点检脚本配合使用：**界面只调用自己目录里的脚本副本**，不直接执行 `D:\scripts-v1.0`。同一 PowerShell 进程内加载 `D:\ImageCheck\scripts-v1.0\checks\*.ps1`，不另开 `powershell.exe`。

- 原稿备份：`D:\scripts-v1.0`（可继续改这里，改完后运行 `D:\ImageCheck\Sync-Scripts.cmd` 同步到界面）
- 图形界面实际执行：`D:\ImageCheck\scripts-v1.0`

无需安装 .NET 8、Visual Studio 或 Node，只需 Windows 自带的 PowerShell 5.1。

---

## 功能介绍

### 自动比对

注册表、驱动版本、电源策略、安全策略、预装软件等项由脚本直接读取并判定：

- **PASS**：当前值与预期一致
- **FAIL**：不一致或执行出错
- **SKIP**：条件不满足（如无权限）时由个别脚本给出
- **MANUAL**：需要人工看界面或截图（任务栏、快速启动、设备管理器黄标等）

### 截图人工项

部分检查会打开设置页、控制面板或设备管理器，截全屏到 `screenshots\`，供人工确认。图形界面在截图过程中保持打开。

### 图形界面（D:\ImageCheck）

- 列出全部点检项，显示编号、名称、结果、当前值、预期值
- 每行前方状态图标：运行中为 loading，通过/失败/人工/跳过为对应图标
- 勾选启用 / 全选 / 全不选 / 按编号或名称筛选
- 运行勾选或运行全部，可中途停止
- 统计：全部、通过、失败、待人工、跳过、含截图项
- **预期值覆盖**：只写入 `D:\ImageCheck\catalog.json`，不修改 `checks\*.ps1`
- 界面与启动器**不写 HKLM / HKCU**（点检脚本只读取注册表做比对）
- 人工通过 / 人工不通过
- 打开对应截图；也可对当前项做「本工具截图」
- 导出 HTML 报告到 `D:\ImageCheck\reports`

### 环境约束

点检以观察客制化系统为准，除明确允许的项外不改系统配置：

- 界面与启动器不写 `HKLM` / `HKCU`；点检脚本只**读取**注册表做比对，不写入
- 不改 BCD、不装驱动
- **50 / 51（多用户软键盘）**：需求就是验证多用户下软键盘，脚本在没有 `newuser` 时会创建该用户，属检查步骤
- 截图、报告、catalog 只写在工具目录（脚本截图在 `ImageCheck\scripts-v1.0\screenshots`，界面额外截图在 `ImageCheck\screenshots`）

---

## 目录结构

```
D:\scripts-v1.0\                 原稿（不由界面直接调用）
  check_all.ps1
  common.ps1
  checks\

D:\ImageCheck\
  CheckUI.ps1            图形界面（同进程执行本目录内脚本副本）
  CheckUI.cmd            启动器（不写注册表）
  Sync-Scripts.cmd      把 D:\scripts-v1.0 复制到本工具 scripts-v1.0（只复制、不执行）
  catalog.json           启用开关、预期值覆盖（不写回脚本）
  scripts-v1.0\          界面实际使用的点检脚本副本
    check_all.ps1
    common.ps1
    checks\
    screenshots\         点检脚本截图
  ui\                    界面 HTML / CSS / JS
  reports\               导出的 HTML 报告
  log\                   执行状态日志（run_时间戳.log、latest.log）
  screenshots\           界面「本工具截图」
```

点检脚本命名：`{两位编号}_{英文简述}.ps1`，例如 `16_password_min_length.ps1`。总控按文件名排序执行。

---

## 使用方法

### 图形界面（推荐）

1. 双击 `D:\ImageCheck.cmd` 或 `D:\ImageCheck\CheckUI.cmd`
2. 等待清单加载（脚本目录为 `D:\ImageCheck\scripts-v1.0`）
3. 勾选要跑的项（或点「全选」）
4. 点 **运行勾选** 或 **运行全部**
5. 对黄色 **MANUAL** 项：打开截图，确认后点「人工通过」或「人工不通过」
6. 需要改某项预期值时，在右侧文本框按行编辑 `$expectedXxx = ...`，再点 **保存预期值**（只进 catalog）
7. 点 **导出报告** 生成 HTML

跑完后窗口关掉也能看结果（每次运行结束都会覆盖写入）：

- HTML：`D:\ImageCheck\reports\last-run.html`（同时会有一份带时间戳的 `report_*.html`）
- JSON：`D:\ImageCheck\reports\last-run.json`
- 执行日志：`D:\ImageCheck\log\latest.log`（每次运行另存 `run_时间戳.log`）
- 截图：`D:\ImageCheck\scripts-v1.0\screenshots\`，界面额外副本在 `D:\ImageCheck\screenshots\`

命令行自检（不弹窗）：

```bat
powershell -NoProfile -STA -ExecutionPolicy Bypass -File D:\ImageCheck\CheckUI.ps1 -SelfTest
```

指定编号自动跑完后退出：

```bat
powershell -NoProfile -STA -ExecutionPolicy Bypass -File D:\ImageCheck\CheckUI.ps1 -AutoRun 14,16 -AutoExit
```

### 命令行（不启动界面）

在 `D:\ImageCheck\scripts-v1.0` 下（与界面同一套副本）：

```powershell
# 全部点检
.\check_all.ps1

# 只跑某一编号（例如密码最小长度）
.\check_all.ps1 -CheckNo 16
```

也可直接执行单个脚本：

```powershell
powershell -NoProfile -File .\checks\16_password_min_length.ps1
```

每条脚本向标准输出打印一行 JSON，例如：

```json
{"no":16,"name":"密码最小长度","status":"PASS","current":"Minimum password length=6","expected":"Minimum password length >= 6"}
```

`check_all.ps1` 汇总后：有 `FAIL` 则进程退出码为 `1`，否则为 `0`。

---

## 如何增删点检项

界面不负责改脚本文件。增删在 **界面使用的副本** `D:\ImageCheck\scripts-v1.0\checks` 完成，然后关掉界面再打开。

若你改的是原稿 `D:\scripts-v1.0`，请再双击 `D:\ImageCheck\Sync-Scripts.cmd`，把文件复制进界面副本（只复制、不执行点检）。

**新增**

1. 复制相近的现有脚本（注册表 / 驱动版本 / 截图）
2. 文件名使用下一个空闲编号，两位数字开头
3. 修改顶部：

```powershell
# === 预期值 ===
$expectedVer = "1.0.0.0"

# === 脚本配置 ===
$checkNo = 66
$checkName = "示例驱动"

. "$PSScriptRoot\..\common.ps1"
# ... 读取当前值并比较 ...
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
```

4. 必须调用 `Write-CheckResult`，以便总控和界面解析 JSON

**删除 / 停用**

- 停用：在界面取消勾选（写入 catalog 的 `enabled`，脚本仍在）
- 删除：从 `checks` 去掉对应 `.ps1`（请确认不再需要）

---

## 如何改预期值

脚本文件顶部的 `$expectedXxx` 是默认标准。

| 方式 | 写入位置 | 是否改脚本 |
|------|----------|------------|
| 直接改 `.ps1` 顶部变量 | `D:\ImageCheck\scripts-v1.0\checks\NN_xxx.ps1` | 会改界面使用的副本 |
| 界面「保存预期值」 | `D:\ImageCheck\catalog.json` | 否；运行时仅在内存中覆盖 |

界面覆盖只在有 catalog 覆盖或脚本含 `exit` 时，在内存里替换后再执行，**不写回** `.ps1`。

---

## 结果含义

| 状态 | 含义 | 建议 |
|------|------|------|
| PASS | 自动判定通过 | 无需操作 |
| FAIL | 与预期不符 | 对照「当前值 / 预期值」处理镜像 |
| MANUAL | 需看截图或界面 | 人工通过或不通过 |
| SKIP | 跳过 | 查看 current 说明原因 |

---

## 点检项一览

| 编号 | 名称 | 类型 |
|------|------|------|
| 01 | 语言包 | 自动 |
| 02 | 电源设置 | 自动 |
| 03 | Touch Keyboard | 截图 MANUAL |
| 04 | BCD fix mode | 自动（无管理员时可能 MANUAL） |
| 05 | Time zone | 截图 MANUAL |
| 06 | UAC | EnableLUA=0 为 MANUAL 并截图；非 0 为 FAIL 仍截图 |
| 07 | Miracast | 截图 MANUAL |
| 08 | HID 设备电源节能 | 自动 |
| 09 | USB 设备电源节能 | 自动 |
| 10 | 任务栏 Touch keyboard | 自动 |
| 11 | Taskbar icons | 截图 MANUAL |
| 12 | 快速启动功能 | 截图 MANUAL |
| 13 | IgnoreSinkScdcRrCapability | 自动 |
| 14 | CVE-2013-3900 | 自动 |
| 15 | Hidden server | 自动 |
| 16 | 密码最小长度 | 自动 |
| 17 | 账户锁定策略 | 自动 |
| 18 | SMB 数字签名 | 自动 |
| 19 | 默认共享和 IPC | 自动 |
| 20 | LM Hashing | 自动 |
| 21 | ICMP Timestamp | 自动 |
| 22 | NetBIOS | 自动 |
| 23 | USB 选择性暂停 | 自动 |
| 24 | 无线设备节能 | 自动 |
| 25 | TCP Timestamps | 自动 |
| 26 | IdeaShare 快捷方式 | 自动 |
| 27 | WMIC 功能 | 自动 |
| 28 | OS Build | 自动 |
| 29 | Defender 版本 | 自动 |
| 30 | Edge 版本 | 自动 |
| 31 | .NET Framework | 自动 |
| 32 | Chipset 驱动 | 自动 |
| 33 | Serial IO 驱动 | 自动 |
| 34 | ME 驱动 | 自动 |
| 35 | VGA 驱动 | 自动 |
| 36 | ISST 驱动 | 自动 |
| 37 | Audio 驱动 | 自动 |
| 38 | RLAN 驱动 | 自动 |
| 39 | WLAN 驱动 | 自动 |
| 40 | BT 驱动 | 自动 |
| 41 | NPU 驱动 | 自动 |
| 42 | PMT 驱动 | 自动 |
| 43 | Realtek USB LAN 驱动 | 自动 |
| 44 | Realtek USB WLAN 驱动 | 自动 |
| 45 | USB RNDIS 驱动 | 自动 |
| 46 | 安装日志 | 自动 |
| 47 | IdeaUI 预装 | 自动 |
| 48 | IdeaShareKey | 自动 |
| 49 | 三指四指触摸 | 截图 MANUAL |
| 50 | 多用户软键盘 | MANUAL（可创建 newuser） |
| 51 | 多用户软键盘按钮 | 同上 |
| 52 | 初始化日志 | 自动 |
| 53 | 系统版本 | 自动 |
| 54 | 系统初始化提示 | 自动 |
| 55 | 系统加密 | 截图 MANUAL |
| 56 | 目标功能更新版本 | 自动 |
| 57 | 禁用预览版本推送 | 自动 |
| 58 | 自动更新配置 | 自动 |
| 59 | 优化配置脚本 | 自动 |
| 60 | ideaUI 启动 | 自动 |
| 61 | 关闭 Hyper-V | 自动 |
| 62 | TCP 端口排除 | 自动 |
| 63 | 静默安装命令 | 自动 |
| 64 | 禁用边缘滑动 | 截图 MANUAL |
| 65 | 设备管理器黄标 | 截图 MANUAL |

---

## 编写新脚本时注意

1. 点源 `common.ps1`，最后用 `Write-CheckResult` 输出一行 JSON
2. 含中文的 `.ps1` 请保存为 **UTF-8 带 BOM**，否则 Windows PowerShell 5.1 可能解析失败
3. 截图类：尽量只关闭**本脚本打开的窗口**；不要按进程名结束全部 `dllhost`
4. 避免 `SendKeys` 误拨设置开关；能读注册表的不要靠点 UI 判定
5. 不要在点检里写入系统策略（50/51 建测试用户除外）

---

## 常见问题

**界面是空白或按钮无反应**  
请用 `D:\ImageCheck.cmd` 或 `CheckUI.cmd` 启动（需要 STA）。界面为 WinForms，不写注册表。

**中文乱码或脚本语法错误**  
检查该 `.ps1` 是否为 UTF-8 BOM。

**截图里出现点检窗口**  
界面保持打开，全屏截图里可能会拍到点检窗口，属预期。

**改了预期值脚本里没变**  
界面保存只更新 `catalog.json`。要改默认标准，请编辑 `D:\ImageCheck\scripts-v1.0\checks\*.ps1` 顶部变量。

**改了 D:\scripts-v1.0，界面还是旧的**  
界面不读取原稿。请运行 `D:\ImageCheck\Sync-Scripts.cmd`，再重新打开界面。
