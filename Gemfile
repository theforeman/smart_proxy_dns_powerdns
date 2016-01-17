source 'https://rubygems.org'
gemspec

if RUBY_VERSION.start_with? '1.8'
  gem 'pg', '< 0.18.0'
end

group :development do
  gem 'smart_proxy', :github => 'theforeman/smart-proxy', :branch => 'develop'
end

group :test do
  gem 'test-unit' unless RUBY_VERSION.start_with? '1.8'
end
