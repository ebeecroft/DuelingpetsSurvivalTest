module UsersHelper

   private
      def getUserParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params.require(:user).permit(:imaginaryfriend, :email,
            :country, :country_timezone, :military_time, :birthday, :login_id,
            :vname, :password, :password_confirmation, :shared)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def getReferrals(user)
         allReferrals = Referral.order("created_on desc")
         value = allReferrals.select{|referral| referral.referred_by_id == user.id}
         return value.count
      end

      def getBanned(user)
         allBanned = Suspendedtimelimit.order("created_on desc")
         user = allBanned.select{|banned| banned.user_id == user.id}
         return user
      end
      
      def changePallet(user)
         webpanel = Webcontrol.find_by_id(1)
         Userinfo.each do |userinfo|
            changecolor = false
            
            #Reverts the color back to the webpanel if a user leaves
            if(Colorscheme.find_by_id(userinfo.daycolor_id).user_id == user.id)
               userinfo.daycolor_id = webpanel.daycolor_id
               changecolor = true
            end
            
            #Reverts the color back to the webpanel if a user leaves
            if(Colorscheme.find_by_id(userinfo.nightcolor_id).user_id == user.id)
               userinfo.nightcolor_id = webpanel.nightcolor_id
               changecolor = true
            end
            
            #Updates the color pallet only if a change has been detected
            if(changecolor)
               @userinfo = userinfo
               @userinfo.save
            end
         end
      end
      
      def showpage
         #Staff, owner, and guests
         logged_in = current_user
         userFound = User.find_by_vname(getUserParams("Id"))
         staff = (logged_in && userFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         owner = (logged_in && userFound && logged_in.id == userFound.id)
         guests = userFound
         
         if(staff || owner || guests)
            #setLastpageVisited
            @user = userFound
         else
            flash[:error] = "The user does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff and owner
         logged_in = current_user
         userFound = User.find_by_vname(getUserParams("Id"))
         staff = (logged_in && userFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         accountOwner = (logged_in && userFound && logged_in.id == userFound.id)
         
         if(staff || accountOwner)
            @user = userFound
            if(type == "update")
               if(@user.update_attributes(getUserParams("User")))
                  flash[:success] = "User #{@user.vname}'s information was successfully updated!"
                  redirect_to user_path(@user)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               if(!userFound.userinfo.admin)
                  changePallet(userFound)
                  @user.destroy
                  flash[:success] = "User #{userFound.vname} was successfully removed!"
                  if(staff)
                     redirect_to users_path
                  else
                     redirect_to root_path
                  end
               else
                  flash[:error] = "The main admin account cannot be removed as this would cause problems!"
                  redirect_to root_path
               end
            end
         else
            if(!userFound)
               flash[:error] = "The user does not exist!"
            else
               flash[:error] = "Only the account owner or staff can delete their account!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
               if(type == "show")
                  showpage
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            if(type == "show")
               showpage
            else
               editCommons(type)
            end
         end
      end

      def mode(type)
         if(timeExpired)
            logoutUser("Single")
            redirect_to root_path
         else
            logoutUser("Multi")
            if(type == "index")
               #Staff only
               logged_in == current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  allUsers = User.order("joined_on desc")
                  @users = Kaminari.paginate_array(allUsers).page(getUserParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
