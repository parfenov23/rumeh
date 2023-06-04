# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

ActionMailer::Base.smtp_settings = {
  :address              => "smtp.yandex.ru",
  :port                 => 465,
  :user_name            => "rumeh.ru@yandex.ru",
  :password             => "PobedaZar66",
  :authentication       => :plain,
  :enable_starttls_auto => true
}