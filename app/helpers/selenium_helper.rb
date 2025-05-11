require 'webdrivers'

module SeleniumHelper
  def setup_selenium
    Webdrivers.install_dir = File.expand_path('~/.webdrivers')
    Webdrivers.cache_time = 86_400 # 24 hours

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--window-size=1400,1400')

    Selenium::WebDriver.for(:chrome, options: options)
  end
end 