# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.site_title = "Dummy"
  config.authentication_method = false
  config.current_user_method   = false
  config.batch_actions = true
end
