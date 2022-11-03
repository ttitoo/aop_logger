# frozen_string_literal: true

module MiraclePlus
  module Logger
    class BaseController < ActionController::Base
      include Concerns::Authentication
    end
  end
end
