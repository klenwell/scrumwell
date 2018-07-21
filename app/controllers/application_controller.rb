class ApplicationController < ActionController::Base
  include SessionsHelper

  def authenticate
    redirect_to auth_confirm_path unless signed_in?
  end

  def auth_group(group_name)
    return true if current_user_in_group?(group_name)

    flash[:error] = "You do not have sufficient permissions to view this resource."
    redirect_to root_url
  end

  def auth_scrum_masters
    auth_group(:scrum_masters)
  end
end
