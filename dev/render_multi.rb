# frozen_string_literal: true

# Renders dev/render_all_spec.rb in parallel and merges the reports into gallery/index.html.
# JOBS processes, default half the cores: more starves the Firefoxes and trips trmnlp's font timeout.
# See "Seeing all possible outputs" in the README.

require 'etc'
require 'fileutils'
require 'json'
require 'open3'
require 'trmnlp/testing/report'

Dir.chdir(File.expand_path('..', __dir__))

SPEC = 'dev/render_all_spec.rb'
# The documentation format prints one line per finished example, indented under "Render all"
EXAMPLE_LINE = /^ +\d{4}-/
BAR_WIDTH = 40

jobs = Integer(ENV.fetch('JOBS', (Etc.nprocessors + 1) / 2))
FileUtils.rm_rf('gallery')
FileUtils.mkdir_p('gallery')

listing, = Open3.capture2('trmnlp', 'test', SPEC, '--dry-run', '--format', 'documentation', err: File::NULL)
total = listing.scan(EXAMPLE_LINE).size

waiters = (1..jobs).map do |i|
  # trmnlp's report appends TEST_ENV_NUMBER to the dir: gallery/shard1, gallery/shard2, ...
  env = { 'RENDER_SHARD' => "#{i}/#{jobs}", 'TEST_ENV_NUMBER' => i.to_s }
  pid = Process.spawn(env, 'trmnlp', 'test', SPEC, '--report', 'gallery/shard', '--format', 'documentation',
                      out: "gallery/shard#{i}.log", err: %i[child out])
  Process.detach(pid)
end

progress = lambda do
  done = Dir['gallery/shard*.log'].sum { File.read(it).scan(EXAMPLE_LINE).size }
  print "\r[#{('#' * (done * BAR_WIDTH / total)).ljust(BAR_WIDTH)}] #{done}/#{total}"
end
progress.call while waiters.any?(&:alive?) && sleep(0.5)
progress.call
puts

failed = (1..jobs).reject { waiters[it - 1].value.success? }
failed.each { puts "shard #{it} failed, see gallery/shard#{it}.log" }

examples = (1..jobs).flat_map do |i|
  path = "gallery/shard#{i}/report.json"
  next [] unless File.exist?(path)

  JSON.parse(File.read(path), symbolize_names: true)[:examples].each do |example|
    example[:screens].each do |screen|
      screen[:image] = "shard#{i}/#{screen[:image]}"
      screen[:outlines] = screen[:outlines].map { it.transform_keys(&:to_s) } # the template reads these by string
    end
  end
end

report = TRMNLP::Testing::Report.new('gallery')
report.instance_variable_set(:@examples, examples.each_with_index.to_h { |example, i| [i, example] })
report.close(nil)
puts "#{examples.size} examples, #{examples.sum { it[:screens].size }} screens: gallery/index.html"

exit(failed.empty?)
