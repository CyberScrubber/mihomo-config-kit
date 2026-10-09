# 维护与贡献

本仓库面向使用自建节点的人。欢迎通过 Issue 或 Pull Request 提出构建、规则、兼容性和文档问题。提交问题时请只提供脱敏后的配置，不要附上服务器地址、UUID、Reality 公钥、short-id、订阅链接或 App 中的全局扩展脚本实值。

修改策略组名称时，同时更新 `config/base.yaml`、`build.rb` 中的名称映射、`config/nodes.example.yaml`、`app/` 里的节点模板和 `README.md`；名称必须与 App 内脚本注入的节点一致。修改后运行 `ruby test/build_test.rb` 和 `ruby build.rb`，检查两种构建模式。`private/`、`dist/` 和 `rulesets/history/` 是本地文件，不提交。

更新上游规则时先运行 `ruby update_rules.rb` 检查差异，再运行 `ruby update_rules.rb --apply` 和 `ruby build.rb`。提交时一并更新 `rulesets/VERSION.json` 与规则快照，并保留上游许可文本。
