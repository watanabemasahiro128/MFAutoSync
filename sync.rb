# frozen_string_literal: true

require 'dotenv'
require 'selenium-webdriver'
require 'sentry-ruby'

Dotenv.load("#{__dir__}/.env")
MONEYFORWARD_EMAIL = ENV['MONEYFORWARD_EMAIL']
MONEYFORWARD_PASSWORD = ENV['MONEYFORWARD_PASSWORD']
SENTRY_DSN = ENV['SENTRY_DSN']

Sentry.init do |config|
  config.dsn = SENTRY_DSN
  config.traces_sample_rate = 1.0
end

begin
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'goog:chromeOptions' => {
      'args' => [
        'headless',
        'disable-gpu',
        'lang=ja-JP',
        'user-agent=Mozilla/5.0 (X11; CrOS aarch64 13597.84.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.106 Safari/537.36',
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
  Sentry.capture_message('Success', level: :info)
rescue StandardError => e
  Sentry.capture_exception(e)
end
