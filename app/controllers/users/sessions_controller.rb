class Users::SessionsController < Devise::SessionsController

  layout "session"
  before_action :admin_logout_required, except: :destroy
  skip_before_action :store_location

  def create
    if warden.authenticate(auth_options)
      super do |resource|
        if resource.remember_me
          flash[:notice] += ts(" <strong>You'll stay logged in for %{number} weeks even if you close your browser, so make sure to log out if you're using a public or shared computer.</strong>", number: ArchiveConfig.DEFAULT_SESSION_LENGTH_IN_WEEKS).html_safe
        end
      end
    else

      if params[:user][:login] && user = User.find_by(login: params[:user][:login])
        self.resource = user
        #resource we have a user
        if user.recently_reset? && params[:user][:password] == user.reset_password_token
          if user.updated_at > 1.week.ago
            # we sent out a generated password and they're using it to log them
            # in
            flash[:notice] = ts('You used a temporary password to log in.
                                Please change it now as it will expire in a
                                week.')

            sign_in(user)
            respond_with(user, location: change_password_user_path(user)) and return
          else
            message = ts("The password you entered has expired. Please click the 'Reset Password' link below.")
          end
        elsif user.active?
          if user.failed_attempts > 50
            message = ts("Your account has been locked for 5 minutes due to too many failed login attempts.")
          else
            message = ts("The password or user name you entered doesn't match our records. Please try again or <a href=\"#{new_password_path}\">reset your password</a>. If you still can't log in, please visit <a href=\"#{admin_posts_path + '/1277'}\">Problems When Logging In</a> for help.".html_safe)
          end
        else
          message = ts("You'll need to activate your account before you can log in. Please check your email or contact support.")
        end
      else
        self.resource = User.new
        message = ts("The password or user name you entered doesn't match our records. Please try again or <a href=\"#{new_password_path}\">reset your password</a>. If you still can't log in, please visit <a href=\"#{admin_posts_path + '/1277'}\">Problems When Logging In</a> for help.".html_safe)
      end
      flash.now[:error] = message
      render action: 'new'
    end
  end

end
