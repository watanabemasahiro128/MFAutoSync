# frozen_string_literal: true

require 'dotenv'
require 'selenium-webdriver'
require 'sentry-ruby'
require_relative 'lib/captcha_annotater'

Dotenv.load("#{__dir__}/.env")
MONEYFORWARD_EMAIL = ENV.fetch('MONEYFORWARD_EMAIL')
MONEYFORWARD_PASSWORD = ENV.fetch('MONEYFORWARD_PASSWORD')
GCP_API_KEY = ENV.fetch('GCP_API_KEY')
SENTRY_DSN = ENV.fetch('SENTRY_DSN')
MONEYFORWARD_ORIGIN = 'https://moneyforward.com'

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

  driver.get("#{MONEYFORWARD_ORIGIN}/accounts")
  sleep 10
  if driver.current_url != "#{MONEYFORWARD_ORIGIN}/accounts"
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
    driver.navigate.to("#{MONEYFORWARD_ORIGIN}/accounts")
    sleep 10
  end
  driver.find_elements(:xpath, '//input[@name="commit"][@value="更新"]').each do |element|
    element.click
    sleep 1
  end
  captcha_urls = driver.find_elements(:tag_name, 'a').select { |element| element.text.include?('要画像認証') }.map { |element| element.attribute('href') }
  captcha_urls.each do |captcha_url|
    driver.navigate.to(captcha_url)
    sleep 30
    driver.navigate.to(captcha_url)
    sleep 60
    source = driver.find_element(:xpath, "//img[@alt='認証用画像']").attribute('src')
    source = Base64.decode64(source.sub(%r{^data:image/(png|jpg|jpeg);base64,}, ''))
    captcha_annotater = CaptchaAnnotater.new(GCP_API_KEY)
    captcha_word = captcha_annotater.annotate(source)
    driver.find_element(:xpath, '//input[@id="additional_request_response_data"]').send_keys(captcha_word)
    driver.find_element(:xpath, '//input[@name="commit"][@value="登録"]').click
    sleep 10
  end

  driver.quit
  Sentry.capture_message('Success', level: :info)
rescue StandardError => e
  Sentry.capture_exception(e)
end
