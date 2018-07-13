class ApplicationController < ActionController::Base
  include SessionsHelper

  def authenticate
    redirect_to auth_confirm_path unless signed_in?
  end
end
