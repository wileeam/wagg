source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Temporary fix till Mechanize version is bumped from 2.7.4 to work with jRuby
gem 'mechanize', github: 'sparklemotion/mechanize', ref: 'master'
gem 'feedjira'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "shoulda", ">= 0"
  gem "rdoc", "~> 3.12"
  gem "bundler", "~> 1.0"
  gem "juwelier", ">= 2.1.1"
  gem "simplecov", ">= 0"
end

group :test do
  gem "travis"
end
