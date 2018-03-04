# Require the gems
#require 'capybara/poltergeist'
require 'pry'
require 'capybara'
#require 'capybara/cucumber'
#require 'capybara/poltergeist'
require 'selenium-webdriver'
# Configure Poltergeist to not blow up on websites with js errors aka every website with js
# See more options at https://github.com/teampoltergeist/poltergeist#customization

#Capybara.register_driver :selenium do |app|
#  profile = Selenium::WebDriver::Firefox::Profile.new
#  Capybara::Selenium::Driver.new( app, :profile => profile)
#end
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end
Capybara.default_wait_time = 10
Capybara.current_driver = :selenium
Capybara.app_host = 'http://www.bestplaces.net'

#Capybara.register_driver :poltergeist do |app|
#  Capybara::Poltergeist::Driver.new(app, js_errors: false, phantomjs_options: ['--web-security=false'])
#end

# Configure Capybara to use Poltergeist as the driver
#Capybara.default_driver = :poltergeist
Capybara.default_driver = :firefox
browser = Capybara.current_session
url = "https://google.com"
url = "http://www.bestplaces.net/city/maryland/baltimore"
browser.visit url
binding.pry
browser.save_and_open_page
binding.pry
