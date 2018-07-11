class SessionsController < ApplicationController
  def new
    # Displays confirmation link
  end

  def create
    google_auth = request.env["omniauth.auth"]

    if google_auth
      auth_token = google_auth[:credentials][:token]
      sign_in auth_token
    else
      redirect_to auth_failure_path
    end
  end

  def destroy
    sign_out
    flash[:notice] = 'You have been signed out.'
    redirect_to root_url
  end

  def failure
    sign_out
    flash[:alert] = 'Authentication failed!'
    render 'new'
  end
end
