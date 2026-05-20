# frozen_string_literal: true

require "fileutils"
require "selenium-webdriver"

SCREENSHOT_DIR = File.expand_path("../../screenshots", __dir__)
FileUtils.mkdir_p(SCREENSHOT_DIR)

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1440,900")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :headless_chrome

module ScreenshotHelpers
  def take_screenshot(name)
    return unless page.driver.respond_to?(:save_screenshot)

    path = File.join(SCREENSHOT_DIR, "#{name}.png")
    page.save_screenshot(path)
    puts "📸 saved #{path}"
    path
  end
end

RSpec.configure do |config|
  config.include ScreenshotHelpers, type: :feature
end
