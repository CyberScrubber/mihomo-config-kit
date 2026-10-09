#!/usr/bin/env ruby
# 手动同步黑矩阵规则快照。默认只检查；--apply 才改动本地文件。
require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require 'yaml'

root = File.expand_path(__dir__)
rule_dir = File.join(root, 'rulesets')
manifest_path = File.join(rule_dir, 'VERSION.json')
repo = 'https://github.com/blackmatrix7/ios_rule_script'
sources = {
  'YouTube' => 'YouTube/YouTube.yaml',
  'Apple' => 'Apple/Apple_Classical.yaml',
  'Steam' => 'Steam/Steam.yaml',
  'Netflix' => 'Netflix/Netflix_Classical.yaml',
  'Claude' => 'Claude/Claude.yaml',
  'OpenAI' => 'OpenAI/OpenAI.yaml',
  'Google' => 'Google/Google.yaml',
  'Spotify' => 'Spotify/Spotify.yaml',
  'ChinaMaxNoIP' => 'ChinaMaxNoIP/ChinaMaxNoIP.yaml'
}
names = sources.keys
apply = ARGV == ['--apply']
abort '用法：ruby update_rules.rb [--apply]' unless ARGV.empty? || apply

begin
  current = JSON.parse(File.read(manifest_path))
  output, error, status = Open3.capture3('git', 'ls-remote', "#{repo}.git", 'refs/heads/master')
  raise "查询上游版本失败：#{error.strip}" unless status.success?
  revision = output.split.first
  raise '未查到有效的上游提交号' unless revision&.match?(/\A[0-9a-f]{40}\z/)
  if revision == current['commit']
    puts "规则已是当前上游版本：#{revision[0, 12]}（本地同步于 #{current['synced_on']}）"
    exit 0
  end

  Dir.mktmpdir('clash-rules-') do |temp_dir|
    names.each do |name|
      url = "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/#{revision}/rule/Clash/#{sources.fetch(name)}"
      target = File.join(temp_dir, "#{name}.yaml")
      _, fetch_error, fetch_status = Open3.capture3('curl', '-fLsS', '--max-time', '30', url, '-o', target)
      raise "下载 #{name} 失败：#{fetch_error.strip}" unless fetch_status.success?
      data = YAML.safe_load(File.read(target))
      payload = data.is_a?(Hash) && data['payload']
      raise "#{name} 规则文件结构无效" unless payload.is_a?(Array) && !payload.empty? && payload.all? { |item| item.is_a?(String) && !item.empty? }
    end
    license_url = "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/#{revision}/LICENSE"
    _, fetch_error, fetch_status = Open3.capture3('curl', '-fLsS', '--max-time', '30', license_url, '-o', File.join(temp_dir, 'LICENSE'))
    raise "下载许可文件失败：#{fetch_error.strip}" unless fetch_status.success?

    changed = names.select do |name|
      Digest::SHA256.file(File.join(rule_dir, "#{name}.yaml")).hexdigest != Digest::SHA256.file(File.join(temp_dir, "#{name}.yaml")).hexdigest
    end
    puts "上游版本：#{revision[0, 12]}；变化：#{changed.empty? ? '规则内容无变化' : changed.join('、')}"
    unless apply
      puts '当前配置未修改。确认后运行 ruby update_rules.rb --apply。'
      exit 0
    end

    backup = File.join(rule_dir, 'history', current.fetch('commit'))
    FileUtils.mkdir_p(backup)
    (names.map { |name| "#{name}.yaml" } + %w[LICENSE VERSION.json]).each do |file|
      FileUtils.cp(File.join(rule_dir, file), File.join(backup, file))
    end
    names.each { |name| FileUtils.cp(File.join(temp_dir, "#{name}.yaml"), File.join(rule_dir, "#{name}.yaml")) }
    FileUtils.cp(File.join(temp_dir, 'LICENSE'), File.join(rule_dir, 'LICENSE'))
    next_manifest = {
      'source' => repo,
      'commit' => revision,
      'synced_on' => Time.now.strftime('%Y-%m-%d'),
      'sha256' => names.to_h { |name| [name, Digest::SHA256.file(File.join(rule_dir, "#{name}.yaml")).hexdigest] }
    }
    File.write(manifest_path, JSON.pretty_generate(next_manifest) + "\n")
    puts "已更新本地规则；旧版本保存在 #{backup}。随后运行 ruby build.rb，再导入生成文件。"
  end
rescue Errno::ENOENT, JSON::ParserError, Psych::Exception, RuntimeError, KeyError => e
  warn "更新失败：#{e.message}"
  exit 1
end
