# Mihomo 自建节点配置工具

一套可修改的 Mihomo 分流模板，面向使用自建节点的人。仓库内置两个美国出口的示例策略，以及 YouTube、ChatGPT、Apple、Steam、Netflix、Grok、Google、Spotify、Claude 等分流组。节点协议示例为 VLESS Reality；你可以按自己的节点修改本地节点文件和策略组。

**支持两种输出：**

| 模式 | 命令 | 生成文件 | 节点参数放在哪里 |
| --- | --- | --- | --- |
| 完整配置 | `ruby build.rb --mode standalone` | `dist/mihomo-standalone.yaml` | 本机 `private/nodes.yaml`；生成文件也含参数 |
| 配置分离 | `ruby build.rb` | `dist/clash-verge.yaml` | Clash Verge Rev 的全局扩展脚本 |

两种模式使用相同的规则和策略组。完整配置可交给支持相应语法的 Mihomo 客户端或 Mihomo 核心使用；配置分离模式生成的文件没有节点，必须由 Clash Verge Rev 的扩展脚本注入后才可运行。这里的“Clash”指 Mihomo 配置格式，不保证旧版 Clash 内核兼容。[Mihomo 的 VLESS 文档](https://wiki.metacubex.one/en/config/proxies/vless/)和[内联规则集文档](https://wiki.metacubex.one/en/config/rule-providers/)可用于检查内核支持情况。

公开仓库只保存示例和规则快照，不保存真实服务器地址、UUID、Reality 公钥或个人规则。`private/` 和 `dist/` 均被 Git 忽略；**完整配置文件包含节点参数，请只在自己的设备和可信渠道使用。**

## 快速开始：生成完整配置

1. 把 [`config/nodes.example.yaml`](config/nodes.example.yaml) 复制到 `private/nodes.yaml`，将两台示例节点的 `server`、`port`、`uuid`、`servername`、`public-key` 和 `short-id` 换成真实值。可按实际协议调整节点字段；每个 `name` 必须与 [`config/base.yaml`](config/base.yaml) 的策略组引用完全一致。
2. 运行 `ruby build.rb --mode standalone`。如果仍有 `REPLACE_` 占位值、节点重名或缺少被引用的节点，构建会报错，不会生成新文件。
3. 将 `dist/mihomo-standalone.yaml` 导入使用 Mihomo 内核的客户端，或交给 Mihomo 核心检查和运行。该文件权限设为仅当前用户可读写；它不会被 Git 跟踪。

默认策略适合两个美国出口的起点：`🇺🇸 美国自动` 每五分钟测试两台节点并择优；`🌵 凤凰城出口` 和 `🌴 洛杉矶出口` 分别固定一台。比如 `⚡ Grok` 默认走凤凰城，`🔎 Google` 默认走自动组。你可以在 [`config/base.yaml`](config/base.yaml) 中修改组名、出口、默认顺序和规则；添加或删除节点时同步修改策略组的 `proxies` 引用与公开的 [`config/nodes.example.yaml`](config/nodes.example.yaml) 名称清单。完整模式允许增加其他 Mihomo 节点类型，最终仍以 Mihomo 的配置校验为准。

## 快速开始：Clash Verge Rev 配置分离

1. 在 Clash Verge Rev 的「订阅」页打开「全局扩展脚本」→「编辑文件」，粘贴 [`app/global-script.example.js`](app/global-script.example.js)，只在 App 内填写真实节点参数并保存。示例脚本仅对包含本项目 `🇺🇸 美国自动` 组和两台指定节点名的配置生效。
2. 运行 `ruby build.rb`，生成 `dist/clash-verge.yaml`。文件中 `proxies: []` 是预期结果。
3. 在 App 中通过「新建配置」→「本地」导入这个文件并选择使用；在「代理」页调整服务组出口。若图标或节点未出现，先检查运行时订阅和扩展脚本的节点名称是否与基础配置一致。

也可以把 [`app/global-merge.example.yaml`](app/global-merge.example.yaml) 填好后用作 App 的全局扩展覆写配置，但它会影响其他配置。**全局脚本和全局覆写二选一。**[Clash Verge Rev 扩展文档](https://www.clashverge.dev/guide/extend.html)说明了两者的作用方式。

App 导入本地文件后会保存副本。规则更新或修改策略后，请重新导入生成文件并检查组选择；全局扩展脚本中的节点参数无需因规则更新而重填。若从早期无 emoji 名称的版本升级，只需在已填好参数的 App 脚本里替换 `美国节点`、`US-Phoenix`、`US-LosAngeles` 三种名称，分别改为 `🇺🇸 美国自动`、`🌵 US-Phoenix`、`🌴 US-LosAngeles`，不要用空白示例覆盖真实参数。

## 自定义分流

[`config/base.yaml`](config/base.yaml) 保存策略组、默认规则和内联规则集定义。示例服务组包括 `📺 YouTube`、`🤖 ChatGPT`、`🍎 Apple`、`🎮 Steam`、`🎬 Netflix`、`⚡ Grok`、`🔎 Google`、`🎵 Spotify`、`🧠 Claude`；Apple 和 Steam 默认直连，其余按组内第一个出口作为默认值。`🚀 默认代理` 处理未命中其他规则的流量。

个人域名和 IP 规则可以放在 `private/personal-rules.yaml`。从 [`config/personal-rules.example.yaml`](config/personal-rules.example.yaml) 复制模板即可；不创建文件也能构建。个人规则排在公开规则之前，可使用 `PROXY`、`GOOGLE` 等旧目标别名，构建时会转成界面上的 emoji 组名。它们和生成文件都不会提交到仓库。如果要添加全新的策略组或节点，请同步更新基础配置与节点示例；使用分离模式时还需更新 App 脚本。构建会检查规则目标和节点引用。

`/32` 只匹配一个 IPv4 地址，`/23` 匹配 512 个地址。复制旧配置的 IP 规则时，请核对网段范围和直连意图。

## 更新规则快照

仓库保存 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) 的固定版本规则。上游提交和各文件哈希见 [`rulesets/VERSION.json`](rulesets/VERSION.json)，来源与许可见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。生成文件已内嵌规则，平时不自动拉取新版；按需要每季度或半年手动同步：

```sh
ruby update_rules.rb           # 只检查上游变化
ruby update_rules.rb --apply   # 更新快照，旧版留在本机 rulesets/history/
ruby build.rb                  # 或 ruby build.rb --mode standalone
```

上游 OpenAI 规则中需要额外 ASN 数据库的 `IP-ASN` 项会在构建时跳过；`GEOIP,CN` 仍依赖客户端维护的地理 IP 数据。更新后应重新导入配置并检查常用网站；需要回退时可从 `rulesets/history/` 恢复旧版快照与 `VERSION.json`。

## 项目文件

| 路径 | 用途 | 是否提交 |
| --- | --- | --- |
| `config/base.yaml` | 默认策略和规则模板 | 是 |
| `config/nodes.example.yaml` | VLESS Reality 节点占位模板 | 是 |
| `app/` | Clash Verge Rev 扩展模板 | 是，仅占位值 |
| `rulesets/` | 固定版本的上游规则和许可 | 是 |
| `private/` | 真实节点和个人规则 | 否 |
| `dist/` | 生成的配置，完整模式含节点参数 | 否 |

构建只依赖 Ruby 标准库；更新规则还需要 Git、curl 和网络连接。仓库的 GitHub Actions 会在每次提交时验证脚本、规则哈希和无私有文件时的构建。`ruby build.rb` 会检查策略组、节点引用和规则目标；完整配置还可用本机 Mihomo 的 `-t` 检查。分离模式文件没有节点，须先由 App 注入后检查。

## 发布与许可

本地仓库已初始化为 `main` 分支。创建 GitHub 空仓库时不要让 GitHub 自动添加 README、忽略文件或许可证；随后添加远程地址并推送：

```sh
git remote add origin git@github.com:<用户名>/<仓库名>.git
git push -u origin main
```

发布前用 `git status --short` 和 `git ls-files` 检查提交范围。本仓库使用 [GPL-2.0 许可](LICENSE)，上游规则保留对应的[许可文本](rulesets/LICENSE)和版本信息。
