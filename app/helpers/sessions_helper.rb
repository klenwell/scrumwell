module SessionsHelper
  def sign_in(google_auth)
    session[:auth_token] = google_auth[:credentials][:token]
    session[:auth_user] = google_auth[:info]
    redirect_to root_path
  end

  def sign_out
    session[:auth_token] = nil
  end

  def signed_in?
    session[:auth_token].present?
  end

  def google_sign_in_path
    '/auth/google_oauth2'
  end

  def current_user
    session[:auth_user] if signed_in?
  end

  def auth_groups
    OpenStruct.new(YAML.load_file(Rails.root.join('config', 'auth_groups.yml')))
  end

  def current_user_in_group?(group_name)
    return false if current_user.blank?
    authorized_group = group_name.to_sym
    user_email = current_user['email']
    auth_groups[authorized_group].include?(user_email)
  end

  def scrum_master?
    current_user_in_group?(:scrum_masters)
  end
end
