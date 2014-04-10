source 'https://rubygems.org'

# Specify your gem's dependencies in net-ping2.gemspec
gemspec

group :test do
  gem "rcov", ">= 0", :platforms => :mri_18
  gem "simplecov", "~> 0.7.1", :require => false, :platforms => :ruby_19
  gem 'ruby-debug-ide', '0.4.23.beta1', :platform => :ruby_19
  gem 'coveralls', :require => false, :git => 'git://github.com/ianheggie/coveralls-ruby.git'
end
    
group :development do
  platforms :ruby do
    # not jruby
    gem "travis", ">= 1.6.0"
    gem "travis-lint", ">= 0"
  end
  if RUBY_VERSION =~ /^1\.8/
    gem 'rake', '< 10.2.0'
    # mime-types 2.0 requires Ruby version >= 1.9.2
    gem "mime-types", "< 2.0"
  else
    gem 'rake'
  end
end
