# 个人工作台 · 精简第一版

交付固定四个文件：vimrc、tmux.conf、DEPLOY.md、install.sh。
只提供下列已确认功能；不要恢复完整版多级菜单。以后每次新增功能先告知用途和按键，确认后再实施。

## Vim：空格加一个键

先 Esc 返回普通模式。没有菜单层级。

| 键 | 功能 |
|---|---|
| e | 打开/收起文件浏览器，方向键选择，Enter打开 |
| w | 保存 |
| q | 退出整个 Vim；有未保存文件时逐项提示 |
| b | 选择已打开文件 |
| a | 普通模式对齐全文；可视模式仅对齐选区 |
| c | 注释/取消注释当前行或选区 |
| j | 跳出当前begin/end，继续下一项 |
| k | 删除光标所在语法块，包含块头、内部代码和结束词，u撤销 |
| y | 当前行或选区复制到系统剪贴板 |
| p | 系统剪贴板粘贴 |
| h | 显示本帮助；帮助内q关闭 |

基础键保留：i输入、Esc退出输入；方向键移动；v/V选择字/行；/搜索、n/N下一个/上一个；u撤销、Ctrl-r重做。
选区按y、整行yy、yw等复制操作会同时写入系统剪贴板；空格y和鼠标复制仍可用。删除/修改不覆盖系统剪贴板，黑洞寄存器不会同步。所有复制入口共用一次写入，避免鼠标或空格y重复触发。

不设置插入模式的操作前缀。先Esc，再用空格a整理、空格j跳出块；else或else if自行输入后Tab补全。已取消空格s。else if填写条件后再Tab进入正文，支持独立else if以及同行end else if两种写法。
空格k删除光标所在的最近一层语法块：begin/end会连同所属的if、else if、else、always、initial、循环或case分支标签一起删除；case/casex/casez会删除到对应endcase。位于分支链中间时保留前后分支并重新连接；删除首个if时，后续else if会提升为if，后续else块会提升为普通begin块。嵌套块按最近一层匹配，忽略注释和字符串。缺少完整配对时不删除。一次u恢复，删除不写入系统剪贴板。

Verilog：inpu后Tab补成input；输入7:0再Tab，得到[7:0]并进入名称栏。空位宽直接Tab跳过。
本配置将.v/.vh固定识别为Verilog，.sv/.svh识别为SystemVerilog，避免Vim把.v识别成V语言。重载配置或切回HDL文件会重新应用补全映射。
output/inout/wire/reg同样使用，端口不自动加wire/reg。
括号自动成对、闭括号越过、空括号成对删除，单引号不补全。
begin后回车补end并缩进，使用行尾begin。
mod或module后Tab一次生成module、端口区、);和endmodule，光标停在模块名位置。输入模块名后再Tab进入端口区。在端口区先Esc再空格j，跳到);后的正文继续输入。手动写模块声明时，分号后回车仍会补缺少的endmodule。
空格a整理全文，每组各自按最长内容对齐：方向、位宽两侧括号、名称、结束符、注释。位宽内部补空格。可视模式下仅整理选区。
空行和不同缩进/语法类型分组；复杂宏和无法识别的声明保持原样。
不逐字符自动重排；整理可一次u撤销。

### 基础语法统一用Tab补全

输入完整关键词或缩写后Tab生成结构，填完条件/名称再Tab进入正文。所有begin保持行尾风格。
不新增菜单或Ctrl前缀。注释、字符串、粘贴模式不展开。支持行尾的 `if (ready) beg<Tab>`、`IDLE: beg<Tab>` 和 `end els<Tab>`。

| 输入 | 展开 |
|---|---|
| always / alw | always @() begin … end；先填写敏感列表 |
| initial / ini | initial begin … end |
| begin / beg | begin … end，直接进入正文 |
| if / else | if () begin … end / else begin … end |
| case / casex / casez | case变体 () … endcase |
| default / def | default: begin … end |
| for | for (; ; ) begin … end；Tab依次填写初值、条件、步进、正文 |
| while / repeat / wait | 条件/次数框架和begin/end |
| forever | forever begin … end |
| function / func、task | 名称及声明 … endfunction/endtask |
| generate / gen、fork | generate … endgenerate / fork … join |
| assign、parameter、localparam | 名称 = 值;；填名称后Tab进入值栏 |
| endcase等结束词 | 仅补全关键词，不生成第二个块；完整end保持end |

.sv/.svh额外支持always_ff、always_comb、always_latch、foreach、interface/endinterface、package/endpackage和logic。
缩写优先精确匹配完整词，否则按上表顺序匹配；例如for不会变成forever，case不会变成casex。
function/task等生成的是编辑框架，返回类型、参数、位宽和具体逻辑由用户填写，不推断电路行为。
不会为case自动添加default分支或为always自动选择时钟与复位信号。
块内的编辑规则：Enter表示继续在当前begin/end里写下一行；完整语句的分号后按Tab表示当前块完成，跳过最近一层end并在下一结构位置继续输入。光标位于自动保留的分号前时也可按Tab。该行为同样适用于if、else if、else、always、循环和带begin/end的case分支。需要在同一块继续写多条语句时使用Enter。parameter/localparam的连续填写优先于块跳出。
parameter/localparam连续填写：名称后Tab进入值栏，填完值再Tab生成下一行同类声明，光标停在新名称位置。光标在分号前或分号后均可，保留缩进及后续已有代码；不自动编号或递增数值。Esc停止填写，空格a统一对齐。仅针对单行、单名称、非空值的声明，值为空时不会生成下一条。

## tmux：Ctrl+b后一个键

| 键 | 功能 |
|---|---|
| v / s | 左右/上下分屏 |
| 方向键 | 切换窗格 |
| z | 最大化/恢复 |
| q | 关闭窗格，先确认 |
| h | 快捷键说明 |

鼠标保留：单击定位/切换，拖边界调整大小，滚轮浏览，拖选松开复制。
Vim接收自身鼠标事件，复制文字不含行号；普通终端由tmux复制模式处理。
tmux复制后保持历史位置，按q返回实时终端。
真彩色、活动窗格边框、深色状态栏保留，不给Vim背景额外染色。

## 离线部署

支持基线：Vim 9.1完整版、tmux 3.3+、Bash、tmux-256color terminfo。主要面向Linux。

```sh
bash install.sh --check
bash install.sh
```

不联网、不遥测、不上传、不自动安装工具、不用sudo。
安装器检查Vim配置与对齐功能，用独立tmux socket校验，不影响现有会话。
旧配置备份到 ~/.local/state/vim-tmux-kit/backup-*，包括符号链接，不修改符号链接的原目标。
相同配置重复安装无改动。运行时缓存位于 ~/.vim/kit-state，不提交Git。

从完整版升级必须保存并重新打开Vim，仅source不能清除旧映射。
现存tmux可执行 `tmux source-file ~/.tmux.conf`；精简版清空prefix表并装入单层键位。
旧窗格TERM不会追溯更新，检查颜色用新窗格。

回退（覆盖现有配置，先保存后来做的配置编辑）：

```sh
bash install.sh --rollback /绝对路径/.local/state/vim-tmux-kit/backup-...
```

回退后重新打开Vim、重载tmux。彻底恢复tmux全部默认选项可能需要用户结束会话后重启服务，不要自动kill-server。

## 给Codex的流程

1. 阅读四文件及本机适用AGENTS.md，检查文件、符号链接、Vim/tmux版本、终端和剪贴板工具。
2. 用户授权部署后直接检查、备份、安装，不加入未经确认的新功能。
3. 若原交付目录是完整版，先将旧四文件整体备份到交付目录之外。
4. 验证单层映射，没有空格总菜单或多级prefix入口。
5. 测试Tab补全、空位宽、括号、嵌套块跳出、else、组对齐与撤销。
6. 独立PTY/tmux发送真实鼠标按下/拖动/释放，读回系统剪贴板，确认之后可继续键盘编辑；测试后恢复剪贴板。
7. 检查脚本的安装、重复安装、符号链接备份和回退。不要构建用户工程或终止正常会话。
8. 比较交付与已安装文件，报告备份目录和如何重新打开应用。

## 兼容边界

剪贴板依次检测Wayland工具、X11 xclip（含~/.local/bin/xclip）、macOS pbcopy/pbpaste。
无工具时可使用Vim的+clipboard或tmux OSC52；后者依赖外层终端，不能保证读取系统剪贴板。
不从未经批准渠道下载工具。tmux用tmux-256color，为常见桌面终端配置RGB；其他终端需现场验证。
主题内置vimrc，不依赖旧colors文件；无81列竖线；配对括号用下划线，不用实心背景。
本版不提供Git菜单、工程检查、实例生成、独立模板菜单、宏菜单、命令搜索或多级菜单；基础语法框架仅通过Tab访问。
