module SessionsHelper
  def sign_in(auth_token)
    session[:auth_token] = auth_token
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
end
