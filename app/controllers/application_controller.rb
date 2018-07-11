class ApplicationController < ActionController::Base
  include SessionsHelper

  def authenticate
    unless signed_in?
      redirect_to auth_confirm_path
    end
  end
end
