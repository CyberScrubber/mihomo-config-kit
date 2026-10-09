require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

class BuildTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir('mihomo-build-test-')
    source = File.expand_path('..', __dir__)
    FileUtils.cp(File.join(source, 'build.rb'), File.join(@root, 'build.rb'))
    FileUtils.mkdir_p(File.join(@root, 'config'))
    FileUtils.cp(File.join(source, 'config', 'base.yaml'), File.join(@root, 'config', 'base.yaml'))
    FileUtils.cp(File.join(source, 'config', 'nodes.example.yaml'), File.join(@root, 'config', 'nodes.example.yaml'))
    FileUtils.cp_r(File.join(source, 'rulesets'), File.join(@root, 'rulesets'))
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def run_build(*args)
    Open3.capture3('ruby', 'build.rb', *args, chdir: @root)
  end

  def write_nodes(nodes)
    path = File.join(@root, 'nodes.yaml')
    File.write(path, YAML.dump('proxies' => nodes))
    path
  end

  def sample_nodes
    ['🌵 US-Phoenix', '🌴 US-LosAngeles'].map do |name|
      { 'name' => name, 'type' => 'direct' }
    end
  end

  def test_split_mode_builds_without_private_files
    _out, err, status = run_build
    assert status.success?, err
    config = YAML.safe_load(File.read(File.join(@root, 'dist', 'clash-verge.yaml')))
    assert_empty config.fetch('proxies')
    refute_empty config.fetch('rule-providers').fetch('OpenAI').fetch('payload')
  end

  def test_standalone_mode_embeds_nodes
    path = write_nodes(sample_nodes)
    _out, err, status = run_build('--mode', 'standalone', '--nodes', path)
    assert status.success?, err
    output = File.join(@root, 'dist', 'mihomo-standalone.yaml')
    config = YAML.safe_load(File.read(output))
    assert_equal sample_nodes, config.fetch('proxies')
    assert_equal 0o600, File.stat(output).mode & 0o777
  end

  def test_standalone_mode_rejects_missing_and_placeholder_nodes
    path = write_nodes([sample_nodes.first])
    _out, err, status = run_build('--mode', 'standalone', '--nodes', path)
    refute status.success?
    assert_includes err, '🌴 US-LosAngeles'

    path = write_nodes(sample_nodes.tap { |nodes| nodes.first['server'] = 'REPLACE_SERVER' })
    _out, err, status = run_build('--mode', 'standalone', '--nodes', path)
    refute status.success?
    assert_includes err, 'REPLACE_'
    refute File.exist?(File.join(@root, 'dist', 'mihomo-standalone.yaml'))
  end

  def test_split_mode_rejects_unknown_node_reference
    path = File.join(@root, 'config', 'base.yaml')
    config = YAML.safe_load(File.read(path))
    config.fetch('proxy-groups').find { |group| group['name'] == '🇺🇸 美国自动' }['proxies'][0] = 'mistyped-node'
    File.write(path, YAML.dump(config))
    _out, err, status = run_build
    refute status.success?
    assert_includes err, 'mistyped-node'
  end
end
