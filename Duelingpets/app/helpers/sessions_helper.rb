module SessionsHelper

   private
      def recoverlogin(type)
         if(type == "findloginpost")
            #Add an additional token as a security feature
            userFound = User.find_by_email(params[:session][:email].downcase)
            #validToken = Pouch.find_by_remember_token(params[:session][:token])
            validUser = (userFound && userFound.pouch.activated)
            
            if(validUser)
               #Retrieves the user's login name
               UserMailer.user_info(userFound, "Findlogin").deliver_now
               flash[:succes] = "Your login name has just been sent directly to your emailbox!"
               redirect_to login_path
            else
               flash[:error] = "The account might not be activated or the email might be incorrect!"
               render "findlogin"
            end
         end
      end

      def activationtime(type)
         if(type == "extendtimepost")
            userFound = User.find_by_login_id(params[:session][:login_id].downcase)
            validUser = (userFound && !userFound.pouch.activated)
            
            if(validUser)
               #Creates a new token for user activation
               time_limit = 1.days.from_now.utc
               userFound.pouch.remember_token = SecureRandom.urlsafe_base64
               userFound.pouch.expiretime = time_limit
               @pouch = userFound.pouch
               @pouch.save
               UserMailer.user_info(userFound, "Resettime").deliver_now
               flash[:success] = "A new token has just been sent directly to your emailbox!"
               redirect_to activate_path
            else
               flash[:error] = "The account might be activated or the login name might be incorrect!"
               render "extendtime"
            end
         end
      end

      def passwordBuilder(userFound)
         #Creates a new password for the user sign in with
         token = SecureRandom.urlsafe_base64
         userFound.password = token
         userFound.password_confirmation = token
         @user = userFound
         @user.save
      end
      
      def alternate_recovery(type)
         if(type == "altemailpost")
            userFound = User.find_by_login_id(params[:session][:login_id].downcase)
            validEmail = (params[:session][:email].downcase)
            validUser = (userFound && validEmail && userFound.pouch.activated)
            
            if(validUser)
               passwordBuilder(userFound)
               UserMailer.altEmail(userFound, email).deliver_now
               flash[:success] = "A new password has just been sent directly to your emailbox!"
               redirect_to login_path
            else
               flash[:error] = "The account might not be activated or the login name/email might be incorrect!"
               render "altemail"
            end
         end
      end

      def recoverpage(type)
         if(type == "recoverpost")
            userFound = User.find_by_login_id(params[:session][:login_id].downcase)
            validUser = (userFound && userFound.pouch.activated)
            
            if(validUser)
               passwordBuilder(userFound)
               UserMailer.user_info(@user, "Resetpassword").deliver_now
               flash[:success] = "A new password has just been sent directly to your emailbox!"
               redirect_to login_path
            else
               flash[:error] = "The account might not be activated or the login name might be incorrect!"
               render "recover"
            end
         end
      end

      def activatepage(type)
         if(type == "activatepost")
            userFound = User.find_by_login_id(params[:session][:login_id].downcase)
            validToken = Pouch.find_by_remember_token(params[:session][:token])
            validUser = (userFound && validToken && userFound.id == validToken.user_id && !userFound.pouch.activated && (currentTime < userFound.pouch.expiretime))
            
            if(validUser)
               #Activates the user's account
               userFound.pouch.activated
               @pouch = userFound.pouch
               @pouch.save
               UserMailer.user_info(@pouch.user, "Info").deliver_now
               flash[:success] = "Now that your account is activated #{userFound.vname}, you can now login into Duelingpets!"
               redirect_to login_path
            else
               if(!userFound || !validToken || userFound.id != validToken.user_id || userFound.pouch.activated)
                  flash.now[:error] = "The account might be activated or the login name/token is incorrect!"
               else
                  flash.now[:error] = "The time to activate the account has expired!"
               end
               render "activate"
            end
         end
      end

      def loginpage(type)
         if(type == "loginpost")
            userFound = User.find_by_login_id(params[:session][:login_id].downcase)
            validPassword = userFound.authenticate(params[:session][:password])
            validUser = (userFound && validPassword && userFound.pouch.activated)
            
            if(validUser)
               #Nulls out the previous website visit and builds the cookie
               time_limit = 2.days.from_now.utc
               cookie_lifespan = time_limit + 1.month
               userFound.pouch.last_visited = nil
               userFound.pouch.signed_out_at = nil
               userFound.pouch.remember_token = SecureRandom.urlsafe_base64
               userFound.pouch.expiretime = time_limit
               cookies[:remember_token] = {:value => userFound.pouch.remember_token, :expires => cookie_lifespan}
               
               if(userFound.pouch.signed_in_at == nil)
                  UserMailer.user_info(userFound, "Welcome").deliver_now
                  flash[:success] = "Greetings #{userFound.vname} welcome to the world of Duelingpets!"
               else
                  flash[:success] = "Squeak! Welcome back #{userFound.vname}, we are happy to see you! Let's play!"
               end
               
               #Logs in the user and sets the current time
               userFound.pouch.signed_in_at = currentTime
               @pouch = userFound.pouch
               @pouch.save
               self.current_user = userFound
               redirect_to user_path(userFound)
            else
               flash.now[:error] = "The account might not be activated or the login name/password is incorrect!"
               render "login"
            end
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Betawriter"))
            if(staff)
               #displayGreeter(type)
               if(type == "login" || type == "loginpost")
                  loginpage(type)
               elsif(type == "activate" || type == "activatepost")
                  activatepage(type)
               elsif(type == "recover" || type == "recoverpost")
                  recoverpage(type)
               elsif(type == "altemail" || type == "altemailpost")
                  alternate_recovery(type)
               elsif(type == "extendtime" || type == "extendtimepost")
                  activationtime(type)
               elsif(type == "findlogin" || type == "findloginpost")
                  recoverlogin(type)
               else
                  logoutUser("Single")
                  redirect_to root_path
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            #displayGreeter(type)
            if(type == "login" || type == "loginpost")
               loginpage(type)
            elsif(type == "activate" || type == "activatepost")
               activatepage(type)
            elsif(type == "recover" || type == "recoverpost")
               recoverpage(type)
            elsif(type == "altemail" || type == "altemailpost")
               alternate_recovery(type)
            elsif(type == "extendtime" || type == "extendtimepost")
               activationtime(type)
            elsif(type == "findlogin" || type == "findloginpost")
               recoverlogin(type)
            else
               logoutUser("Single")
               redirect_to root_path
            end
         end
      end

      def mode(type)
         if(type == "login" || type == "loginpost" || type == "activate" || type == "activatepost")
            #Guests
            callMaintenance(type)
         elsif(type == "recover" || type == "recoverpost" || type == "altemail" || type == "altemailpost")
            #Guests
            callMaintenance(type)
         elsif(type == "extendtime" || type == "extendtimepost" || type == "findlogin" || type == "findloginpost" || type == "destroy")
            #Guests
            callMaintenance(type)
         end
      end
end
