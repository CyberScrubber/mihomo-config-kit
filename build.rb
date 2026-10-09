#!/usr/bin/env ruby
require 'fileutils'
require 'digest'
require 'json'
require 'yaml'

root = File.expand_path(__dir__)
base_path = File.join(root, 'config', 'base.yaml')
rules_path = File.join(root, 'private', 'personal-rules.yaml')
output_path = File.join(root, 'dist', 'clash-verge.yaml')

read_yaml = lambda do |path|
  value = YAML.safe_load(File.read(path), aliases: true)
  raise "#{path} 的顶层必须是 YAML 对象" unless value.is_a?(Hash)
  value
end

begin
  config = read_yaml.call(base_path)
  personal = File.file?(rules_path) ? read_yaml.call(rules_path) : { 'rules' => [] }
  manifest = JSON.parse(File.read(File.join(root, 'rulesets', 'VERSION.json')))
  rules = personal.fetch('rules')
  raise '个人 rules 必须是字符串列表' unless rules.is_a?(Array) && rules.all? { |r| r.is_a?(String) && !r.empty? }

  group_names = config.fetch('proxy-groups').map { |group| group.fetch('name') }
  expected_names = ['🌵 US-Phoenix', '🌴 US-LosAngeles']
  auto_group = config.fetch('proxy-groups').find { |group| group['name'] == '🇺🇸 美国自动' }
  raise '🇺🇸 美国自动必须引用固定的两台服务器名称' unless auto_group && auto_group['proxies'] == expected_names
  raise '基础配置的 proxies 必须为空，节点只在 App 中维护' unless config.fetch('proxies') == []
  # 私有规则继续使用旧的稳定目标名，生成时转换成 App 中可见的 emoji 名称。
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
    raise "规则引用了未知策略组：#{rule}" unless group_names.include?(target) || %w[DIRECT REJECT].include?(target)
  end
  config.fetch('proxy-groups').each do |group|
    targets = group.fetch('proxies')
    raise "策略组 #{group['name']} 的 proxies 不能为空" unless targets.is_a?(Array) && !targets.empty?
    targets.each do |target|
      next if group_names.include?(target) || expected_names.include?(target) || %w[DIRECT REJECT].include?(target)
      raise "策略组 #{group['name']} 引用了未知节点或策略组：#{target}"
    end
  end
  config.fetch('rule-providers').each do |name, provider|
    snapshot = File.join(root, 'rulesets', "#{name}.yaml")
    actual_hash = Digest::SHA256.file(snapshot).hexdigest
    raise "#{name} 规则快照与版本记录不一致" unless actual_hash == manifest.fetch('sha256').fetch(name)
    payload = read_yaml.call(snapshot).fetch('payload')
    raise "#{name} 规则快照为空或格式无效" unless payload.is_a?(Array) && !payload.empty? && payload.all? { |item| item.is_a?(String) && !item.empty? }
    # 上游 OpenAI 集含一条 IP-ASN 规则；它需要另下载 ASN 数据库。
    # 此处保留快照原文，只在生成配置时跳过 ASN 规则。
    provider['payload'] = payload.reject { |item| item.start_with?('IP-ASN,', 'SRC-IP-ASN,') }
  end
  FileUtils.mkdir_p(File.dirname(output_path))
  File.open(output_path, File::WRONLY | File::CREAT | File::TRUNC, 0600) do |file|
    file.write("# blackmatrix7/ios_rule_script commit: #{manifest.fetch('commit')}\n")
    file.write(YAML.dump(config))
  end
  File.chmod(0600, output_path)
  puts "已生成 #{output_path}（无节点凭据，#{rules.length} 条个人规则）"
rescue Errno::ENOENT => e
  warn "找不到文件：#{e.message}"
  exit 1
rescue JSON::ParserError, Psych::Exception, RuntimeError, KeyError => e
  warn "生成失败：#{e.message}"
  exit 1
end
