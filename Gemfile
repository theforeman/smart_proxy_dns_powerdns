source 'https://rubygems.org'
gemspec

group :development do
  gem 'smart_proxy', :github => 'theforeman/smart-proxy', :branch => 'develop'
end

group :test do
  gem 'coveralls', require: false
  gem 'test-unit'
  gem 'webmock'
  gem 'rack', '~> 1.0', :require => false if RUBY_VERSION < '2.2.2'
  if RUBY_VERSION < '2.2.2'
    gem 'rack-test', '~> 0.7.0'
  else
    gem 'rack-test'
  end
end
