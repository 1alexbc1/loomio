source 'http://rubygems.org'

gem 'rails', '3.1.1'
gem "haml-rails"
gem 'devise', '1.4.9'
gem 'mysql2'
gem 'pg'
gem 'capistrano'
gem 'jquery-rails'
gem 'inherited_resources'
gem 'formtastic'
gem 'twitter-bootstrap-rails', :git => 'http://github.com/seyhunak/twitter-bootstrap-rails.git'
gem 'formtastic-bootstrap'
gem 'jqplot-rails'
gem "rails-backbone"
gem 'coffee-filter'
gem 'acts-as-taggable-on', '~> 2.2.2', :git => 'https://github.com/mbleigh/acts-as-taggable-on.git'
gem 'aasm'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

#group :development do
#end
#gem 'jquery-rails'


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'


group :development, :test do
  gem 'machinist', '>= 2.0.0.beta2'
  gem 'faker'
  gem 'rspec-rails', '>= 2.6.0.rc2'
  gem 'capybara'
  gem 'database_cleaner'
end

group :development do
  gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'guard'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem 'launchy'
  gem 'spork'
end

group :test do
  gem 'cane', :git => 'git://github.com/square/cane.git'
  gem 'simplecov', :require => false
  gem 'flay', :require => false
end

# group :development do
#   gem 'sqlite3'
# end

# group :test do
#   # Pretty printed test output
# #  gem 'turn', :require => false
# end
