Gem::Specification.new do |s|
  s.name = 'grumblr'
  s.version = File.open('VERSION') { |f| f.read }
  s.author = 'Paul Philippov'
  s.description = "Grumblr is a message poster to Tumblr blogs."
  s.email = 'themactep@gmail.com'
  s.bindir = "bin"
  s.executables = ['grumblr']
  s.extra_rdoc_files = ['README', 'LICENSE', 'VERSION', 'Changelog']
  s.files = Dir.glob("{bin,data,lib,spec}/**/*") + \
            %w(LICENSE README VERSION Changelog grumblr.gemspec setup.rb)
  s.homepage = 'http://themactep.com/grumblr/'
  s.require_path = "lib"
  s.rubyforge_project = 'grumblr'
  s.summary = "a Tumblr companion"
  s.has_rdoc = false
  s.add_dependency "ppds-libs"
  s.add_dependency "libxml-ruby"
  s.add_dependency "rest-client", '>= 1.6.0'
end
