# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_provisioning_ssh/version'

Gem::Specification.new do |s|
  s.name          = "chef-provisioning-ssh"
  s.version       = ChefProvisioningSsh::VERSION
  s.platform      = Gem::Platform::RUBY
  s.author        = "Zack Zondlo"
  s.email         = "zackzondlo@gmail.com"
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt' ]
  s.summary = 'Provisioner for managing servers using ssh in Chef Provisioning.'
  s.description = s.summary
  s.homepage = 'https://github.com/double-z/chef-metal-ssh'

  s.require_path  = "lib"
  s.bindir       = "bin"
  s.executables  = %w( )
  s.files = %w(Rakefile LICENSE.txt README.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }

  s.add_dependency 'chef'
  s.add_dependency 'chef-provisioning', '~> 0.17'

  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
end
