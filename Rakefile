require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'grumblr'
  s.version = File.open('VERSION') { |f| f.read }
  s.has_rdoc = false
  s.extra_rdoc_files = ['README', 'LICENSE', 'Changelog', 'VERSION']
  s.summary = "Tumblr companion for GNOME"
  s.description = "Grumblr is a message poster to Tumblr blogs from GNOME"
  s.author = 'Paul Philippov'
  s.email = 'themactep@gmail.com'
  s.homepage = 'http://themactep.com/grumblr/'
  s.rubyforge_project = 'grumblr'
  s.executables = ['grumblr']
  s.files = Dir.glob("{bin,data,lib,spec}/**/*") + \
            %w(LICENSE README Rakefile Changelog VERSION)
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency "ppds-libs"
  s.add_dependency "libxml-ruby"
  s.add_dependency "rest-client", '>= 1.3.0'
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "grumblr Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
end