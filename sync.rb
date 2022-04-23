# frozen_string_literal: true

require 'dotenv'
require 'selenium-webdriver'

Dotenv.load("#{__dir__}/.env")
MONEYFORWARD_EMAIL = ENV['MONEYFORWARD_EMAIL']
MONEYFORWARD_PASSWORD = ENV['MONEYFORWARD_PASSWORD']

capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
  'goog:chromeOptions' => {
    'args' => [
      'headless',
      'disable-gpu',
      'lang=ja-JP',
      <<~USER_AGENT,
        user-agent=Mozilla/5.0 (X11; CrOS armv7l 13597.84.0)
        AppleWebKit/537.36 (KHTML, like Gecko)
        Chrome/92.0.4515.98
        Safari/537.36
      USER_AGENT
      "user-data-dir=#{__dir__}/user_data"
    ]
  }
)
driver = Selenium::WebDriver.for(:chrome, capabilities:)
driver.manage.timeouts.implicit_wait = 10

driver.get('https://moneyforward.com/accounts')
sleep 10
if driver.current_url != 'https://moneyforward.com/accounts'
  unless driver.current_url.start_with?('https://id.moneyforward.com/account_selector')
    driver.navigate.to('https://id.moneyforward.com/sign_in/email')
    sleep 10
    driver.find_element(:name, 'mfid_user[email]').send_keys(MONEYFORWARD_EMAIL)
    sleep 1
    driver.find_element(:class, 'submitBtn').click
    sleep 1
    driver.find_element(:name, 'mfid_user[password]').send_keys(MONEYFORWARD_PASSWORD)
    sleep 1
  end
  driver.find_element(:class, 'submitBtn').click
  sleep 10
  driver.navigate.to('https://moneyforward.com/accounts')
  sleep 10
end
driver.find_elements(:name, 'commit').each do |element|
  if element.attribute('value') == '更新'
    element.click
    sleep 1
  end
end

driver.quit
