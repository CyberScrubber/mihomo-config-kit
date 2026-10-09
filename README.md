# 我的 Clash Verge Rev 配置

这是供两台自建 VLESS Reality 服务器使用的 Clash Verge Rev 配置模板，不使用机场节点。仓库保存策略组、构建脚本和固定版本的分流规则；**服务器地址、UUID、Reality 公钥等参数只填在每台设备的 Clash Verge Rev 全局扩展脚本中**。公开分流规则来自 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)，版本见 [`rulesets/VERSION.json`](rulesets/VERSION.json)，来源和许可见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。

仓库中的 `config/base.yaml` 没有真实节点，公开提交也不包含 `private/` 或生成的 `dist/`。`dist/clash-verge.yaml` 不含节点参数，但如果你添加了个人规则，它会包含其中的域名和 IP，因此仍留在本机。全新克隆后不创建 `private/personal-rules.yaml` 也可以直接构建。

## 仓库结构

| 路径 | 用途 | 提交到 Git |
| --- | --- | --- |
| `config/base.yaml` | 策略组、默认规则及占位节点列表 | 是 |
| `rulesets/` | 带版本和哈希记录的上游规则快照 | 是 |
| `app/` | 粘贴到 App 的占位模板 | 是，仅占位值 |
| `build.rb`、`update_rules.rb` | 构建和手动更新规则 | 是 |
| `private/personal-rules.yaml` | 本机自定义规则 | 否 |
| `dist/clash-verge.yaml` | 生成后供 App 导入的文件 | 否 |

构建只需要 Ruby 标准库；手动更新规则还需要 Git、curl 和网络连接。GitHub Actions 会在每次提交时验证脚本和无个人文件的构建流程。

## 第一次使用

1. 在 Clash Verge Rev 的「订阅」页找到「全局扩展脚本」，打开「编辑文件」。把 [`app/global-script.example.js`](app/global-script.example.js) 的内容粘贴进去，只在 App 内填入凤凰城、洛杉矶两台服务器的真实参数，然后保存。节点名称保持 `🌵 US-Phoenix`、`🌴 US-LosAngeles`。脚本只会为含有本项目「🇺🇸 美国自动」策略组的配置注入这两台节点，不会修改其他配置。原脚本里的 `fp` 与 `client-fingerprint` 重复，这里只保留 Mihomo 文档中的 `client-fingerprint`。
2. 如需个人规则，把 [`config/personal-rules.example.yaml`](config/personal-rules.example.yaml) 复制为 `private/personal-rules.yaml` 后编辑。不需要个人规则时跳过此步；此目录不会上传到 GitHub。
3. 在项目目录运行 `ruby build.rb`，得到 `dist/clash-verge.yaml`。该文件的 `proxies` 为空，这是预期行为；App 会在加载时执行全局脚本，填入两个节点。
4. 在 App「订阅」页选择「新建配置」→「本地」→「选择文件」，导入 `dist/clash-verge.yaml` 并选择「使用」。首页选「规则模式」，按需开启「系统代理」。在「代理」页可分别调整各服务组的出口。

**也可以使用全局扩展覆写配置：**[`app/global-merge.example.yaml`](app/global-merge.example.yaml) 是 YAML 模板，填好参数后可粘贴到 App 的「全局扩展覆写配置」。源码表明，它会把 `proxies` 数组整体替换，且会作用于其他配置。因此只在 App 中仅使用这份个人配置时采用。**脚本和覆写二选一，不要同时填入两份节点。**

**本地配置的更新行为：**Clash Verge Rev 导入 YAML 后会在自己的 `profiles` 目录保存副本。项目重新生成文件后，在「订阅」页再次导入新文件、切换到新卡片、检查服务组选择，再删除旧卡片。全局脚本里的服务器参数保持在 App 中，无需随每次规则更新重填。

## 在另一台设备使用

从 GitHub 克隆仓库后运行 `ruby build.rb`，再按上面的首次使用步骤，在那台设备的 App 中填写两台服务器参数并导入生成文件。公开仓库只同步规则和配置模板；App 中的服务器参数、个人规则以及每个策略组在界面中的手动选择不会随 Git 同步。个人规则如需跨设备共享，请自行通过私密渠道复制 `private/personal-rules.yaml`。

**从无 emoji 的旧版升级：**先把新版 `dist/clash-verge.yaml` 导入 App，暂不切换。然后在 App 已填好服务器参数的全局扩展脚本中做三次全局替换：`美国节点` → `🇺🇸 美国自动`、`US-Phoenix` → `🌵 US-Phoenix`、`US-LosAngeles` → `🌴 US-LosAngeles`。保存脚本后立刻切换到新版配置。只改名称，不要用示例脚本覆盖你已填好的服务器参数。由于策略组名称也变了，首次使用新版配置时检查并重新选择各组出口；旧版配置可以留到新版确认正常后再删除。

## 分流与策略组

| 命中的流量 | 策略组 | 默认出口 | App 中可选 |
| --- | --- | --- | --- |
| YouTube 规则集 | `📺 YouTube` | `🇺🇸 美国自动` | 凤凰城、洛杉矶、直连 |
| ChatGPT、OpenAI 规则集 | `🤖 ChatGPT` | `🇺🇸 美国自动` | 凤凰城、洛杉矶 |
| Apple 规则集 | `🍎 Apple` | 直连 | 美国自动、凤凰城、洛杉矶 |
| Steam 规则集 | `🎮 Steam` | 直连 | 美国自动、凤凰城、洛杉矶 |
| Netflix 规则集 | `🎬 Netflix` | `🇺🇸 美国自动` | 凤凰城、洛杉矶 |
| `grok.com`、`x.ai`（含 `api.x.ai`） | `⚡ Grok` | 凤凰城 | 美国自动、洛杉矶 |
| Google 规则集 | `🔎 Google` | `🇺🇸 美国自动` | 凤凰城、洛杉矶 |
| Spotify 规则集 | `🎵 Spotify` | `🇺🇸 美国自动` | 凤凰城、洛杉矶、直连 |
| Claude、Anthropic 规则集 | `🧠 Claude` | `🇺🇸 美国自动` | 凤凰城、洛杉矶 |
| 旧脚本指定的企业域名和 IP、国内域名/IP | `DIRECT` | 直连 | 无需选择 |
| 旧脚本指定的其他代理域名、剩余流量 | `🚀 默认代理` | `🇺🇸 美国自动` | 凤凰城、洛杉矶、直连 |

`🇺🇸 美国自动` 每 5 分钟用 `https://www.gstatic.com/generate_204` 测试两台节点，在两台中选一台，不会按请求随机分流或同时负载均衡。`🌵 凤凰城出口` 固定使用 `🌵 US-Phoenix`，`🌴 洛杉矶出口` 固定使用 `🌴 US-LosAngeles`。例如 `🔎 Google` 选 `🇺🇸 美国自动`，`⚡ Grok` 选 `🌵 凤凰城出口`，两组互不影响。Apple、Steam 默认直连；Spotify 只有美国出口，不再使用旧机场的日本节点。

策略组和节点用名称开头的 emoji 标识，与普通订阅中的命名方式相同，不依赖在线图标服务或 App 的「代理组图标」开关。`private/personal-rules.yaml` 中仍可用 `PROXY`、`GOOGLE` 等旧目标名；`build.rb` 会把它们转换为界面上的 emoji 名称。

个人规则排在最前面，然后是服务规则集、国内直连和最终兜底。`/32` 只匹配**一个** IPv4 地址；`/23` 会匹配 **512 个**地址。例如 `172.80.1.2/23` 实际覆盖 `172.80.0.0` 到 `172.80.1.255`。若从旧配置复制 IP 规则，请核对网段范围和直连意图。

## 每季度或半年更新规则

规则集是本地快照，生成时直接内嵌到最终 YAML。App 平时不会自行拉取这些规则的新版；使用的上游提交和哈希见 `rulesets/VERSION.json`。上游 OpenAI 规则中有一条 `IP-ASN`，需要额外的 ASN 数据库；生成时会跳过该条，其余快照保持原文。

```sh
ruby update_rules.rb           # 只检查上游版本与变化
ruby update_rules.rb --apply   # 更新快照，旧版备份到 rulesets/history/
ruby build.rb                  # 重新生成不含节点凭据的配置
```

再把新的 `dist/clash-verge.yaml` 作为本地配置导入 App，检查常用网站和策略组。若新规则不合适，可从 `rulesets/history/` 恢复旧版文件及 `VERSION.json`，重新生成。季度和半年都可以。`GEOIP,CN` 使用 Mihomo/Verge 的地理 IP 数据，由客户端另行管理。

DNS、TUN、系统代理由 Clash Verge Rev 设置管理。

## 连接未来的 GitHub 仓库

在 GitHub 新建**空仓库**，不要让 GitHub 自动添加 README、`.gitignore` 或 LICENSE。之后在本项目目录执行：

```sh
git remote add origin git@github.com:<你的用户名>/<仓库名>.git
git push -u origin main
```

发布前运行 `git status --short` 与 `git ls-files`，确认没有把真实服务器参数、个人规则和生成文件提交。仓库默认采用 [GPL-2.0 许可](LICENSE)；上游规则保留其原始许可和版本记录。

## 验证

`ruby build.rb` 会检查规则集哈希和策略组引用。由于生成文件故意不含节点，**不能单独用 Mihomo 的 `-t` 检查它**；应在 App 的「订阅」页查看「运行时订阅」，确认全局脚本已注入两台节点，再测试连接。若脚本报错，Clash Verge Rev 会保留注入前的配置；检查全局脚本的日志与运行时配置。
