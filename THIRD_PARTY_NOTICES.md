# 第三方内容

`rulesets/*.yaml` 是从 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) 保存的规则快照。具体上游提交、同步日期和各文件 SHA-256 见 [`rulesets/VERSION.json`](rulesets/VERSION.json)。规则文件的许可文本保留在 [`rulesets/LICENSE`](rulesets/LICENSE)。

`update_rules.rb` 从上游同一个提交下载规则和许可文本；`build.rb` 将规则内嵌到两种模式生成的 Mihomo 配置中。生成文件因此包含这些第三方规则。

Clash Verge Rev 和 Mihomo 由各自项目维护；本仓库提供配置构建模板，不包含它们的程序文件。
