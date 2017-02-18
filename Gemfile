source 'https://rubygems.org'
gemspec

if RUBY_VERSION.start_with? '1.8'
  gem 'pg', '< 0.18.0'
end

group :development do
  gem 'smart_proxy', :github => 'theforeman/smart-proxy', :branch => 'develop'
end

group :test do
  gem 'coveralls', require: false
  gem 'test-unit'
  gem 'webmock'
  gem 'rack', '~> 1.0', :require => false if RUBY_VERSION < '2.2.2'
end
