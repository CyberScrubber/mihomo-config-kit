#!/usr/bin/env ruby
# Build a Mihomo config with either app-side node injection or local nodes.
require 'digest'
require 'fileutils'
require 'json'
require 'optparse'
require 'yaml'

root = File.expand_path(__dir__)
options = { mode: 'split', nodes: 'private/nodes.yaml' }
parser = OptionParser.new do |opts|
  opts.banner = '用法：ruby build.rb [--mode split|standalone] [--nodes PATH]'
  opts.on('--mode MODE', %w[split standalone], 'split（默认）或 standalone') { |value| options[:mode] = value }
  opts.on('--nodes PATH', 'standalone 模式的本地节点文件，默认 private/nodes.yaml') do |value|
    options[:nodes] = value
  end
  opts.on('-h', '--help', '显示帮助') { puts opts; exit 0 }
end

read_yaml = lambda do |path|
  value = YAML.safe_load(File.read(path), aliases: true)
  raise "#{path} 的顶层必须是 YAML 对象" unless value.is_a?(Hash)
  value
end

begin
  parser.parse!
  raise "未知参数：#{ARGV.join(' ')}" unless ARGV.empty?
  raise '--nodes 只能用于 standalone 模式' if options[:mode] == 'split' && options[:nodes] != 'private/nodes.yaml'

  config = read_yaml.call(File.join(root, 'config', 'base.yaml'))
  rules_path = File.join(root, 'private', 'personal-rules.yaml')
  personal = File.file?(rules_path) ? read_yaml.call(rules_path) : { 'rules' => [] }
  manifest = JSON.parse(File.read(File.join(root, 'rulesets', 'VERSION.json')))
  rules = personal.fetch('rules')
  raise '个人 rules 必须是字符串列表' unless rules.is_a?(Array) && rules.all? { |rule| rule.is_a?(String) && !rule.empty? }
  raise '基础配置的 proxies 必须为空' unless config.fetch('proxies') == []

  groups = config.fetch('proxy-groups')
  raise 'proxy-groups 必须是非空对象列表' unless groups.is_a?(Array) && !groups.empty? && groups.all? { |group| group.is_a?(Hash) }
  group_names = groups.map { |group| group.fetch('name') }
  raise '策略组名称有重复' unless group_names.uniq == group_names
  builtins = %w[DIRECT REJECT]
  required_nodes = groups.flat_map do |group|
    targets = group.fetch('proxies')
    raise "策略组 #{group['name']} 的 proxies 不能为空" unless targets.is_a?(Array) && !targets.empty?
    targets.reject { |target| group_names.include?(target) || builtins.include?(target) }
  end.uniq
  raise '策略组未引用任何节点' if required_nodes.empty?
  example_nodes = read_yaml.call(File.join(root, 'config', 'nodes.example.yaml')).fetch('proxies')
  raise '示例节点 proxies 必须是非空对象列表' unless example_nodes.is_a?(Array) && !example_nodes.empty? && example_nodes.all? { |node| node.is_a?(Hash) && node['name'].is_a?(String) && !node['name'].empty? }
  example_names = example_nodes.map { |node| node.fetch('name') }
  raise '示例节点名称有重复' unless example_names.uniq == example_names
  unknown_nodes = required_nodes - example_names
  raise "策略组引用了未在 config/nodes.example.yaml 声明的节点：#{unknown_nodes.join('、')}" unless unknown_nodes.empty?

  # Local rules can keep stable aliases even when display names use emoji.
  display_names = {
    'PROXY' => '🚀 默认代理', 'YOUTUBE' => '📺 YouTube',
    'CHATGPT' => '🤖 ChatGPT', 'APPLE' => '🍎 Apple',
    'STEAM' => '🎮 Steam', 'NETFLIX' => '🎬 Netflix',
    'GROK' => '⚡ Grok', 'CLAUDE' => '🧠 Claude',
    'GOOGLE' => '🔎 Google', 'SPOTIFY' => '🎵 Spotify'
  }
  rendered_rules = rules.map do |rule|
    parts = rule.split(',', -1)
    target_index = parts[0] == 'MATCH' ? 1 : 2
    parts[target_index] = display_names.fetch(parts[target_index], parts[target_index]) if parts.length > target_index
    parts.join(',')
  end
  config['rules'] = rendered_rules + config.fetch('rules')
  config.fetch('rules').each do |rule|
    parts = rule.split(',')
    target = parts[parts[0] == 'MATCH' ? 1 : 2]
    raise "规则引用了未知策略组：#{rule}" unless group_names.include?(target) || builtins.include?(target)
  end

  config.fetch('rule-providers').each do |name, provider|
    snapshot = File.join(root, 'rulesets', "#{name}.yaml")
    actual_hash = Digest::SHA256.file(snapshot).hexdigest
    raise "#{name} 规则快照与版本记录不一致" unless actual_hash == manifest.fetch('sha256').fetch(name)
    payload = read_yaml.call(snapshot).fetch('payload')
    raise "#{name} 规则快照为空或格式无效" unless payload.is_a?(Array) && !payload.empty? && payload.all? { |item| item.is_a?(String) && !item.empty? }
    # The upstream OpenAI IP-ASN entry requires an additional ASN database.
    provider['payload'] = payload.reject { |item| item.start_with?('IP-ASN,', 'SRC-IP-ASN,') }
  end

  if options[:mode] == 'standalone'
    nodes_path = File.expand_path(options[:nodes], root)
    raise "缺少节点文件：#{nodes_path}。请复制 config/nodes.example.yaml 到 private/nodes.yaml 并填写" unless File.file?(nodes_path)
    nodes = read_yaml.call(nodes_path).fetch('proxies')
    raise '节点文件的 proxies 必须是非空列表' unless nodes.is_a?(Array) && !nodes.empty?
    raise '每个节点都需要非空的 name 和 type' unless nodes.all? { |node| node.is_a?(Hash) && node['name'].is_a?(String) && !node['name'].empty? && node['type'].is_a?(String) && !node['type'].empty? }
    node_names = nodes.map { |node| node.fetch('name') }
    raise '节点名称有重复' unless node_names.uniq == node_names
    missing = required_nodes - node_names
    raise "缺少策略组引用的节点：#{missing.join('、')}" unless missing.empty?
    raise '节点文件仍含 REPLACE_ 占位值' if nodes.to_s.include?('REPLACE_')
    config['proxies'] = nodes
    output_path = File.join(root, 'dist', 'mihomo-standalone.yaml')
  else
    output_path = File.join(root, 'dist', 'clash-verge.yaml')
  end

  FileUtils.mkdir_p(File.dirname(output_path))
  File.open(output_path, File::WRONLY | File::CREAT | File::TRUNC, 0600) do |file|
    file.write("# blackmatrix7/ios_rule_script commit: #{manifest.fetch('commit')}\n")
    file.write(YAML.dump(config))
  end
  File.chmod(0600, output_path)
  puts "已生成 #{output_path}（#{options[:mode]} 模式，#{config['proxies'].length} 个节点，#{rules.length} 条本地规则）"
rescue OptionParser::ParseError, Errno::ENOENT, JSON::ParserError, Psych::Exception, RuntimeError, KeyError => e
  warn "生成失败：#{e.message}"
  exit 1
end
