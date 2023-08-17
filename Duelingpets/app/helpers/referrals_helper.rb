module ReferralsHelper

   private
      def getReferralParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Referral")
            value = params.require(:referral).permit(:referred_by_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def discoverpage
         logged_in = current_user
         discovered = (logged_in && logged_in.referral.nil?)
         if(discovered)
            #Referral for users who found the site on their own. (This code will be replaced later!)
            newReferral = Referral.new
            newReferral.user_id = logged_in.id
            newReferral.created_on = currentTime
            newReferral.referred_by_id = 1
            @user = User.find_by_vname(logged_in.vname)
            @referral = newReferral
            @referral.save
            
            #Gives the player points for the referral
            referralPoints = Fieldcost.find_by_name("Referral")
            pouch = Pouch.find_by_id(@referral.referred_by_id)
            pouch.amount += referralPoints.amount
            @pouch = pouch
            @pouch.save
            economyTransaction("Source", referralPoints.amount, pouch.user.id, "Points")
            
            #Emails the user about the new referral
            ContentMailer.content_created(@referral, "Referral", referralPoints.amount).deliver_now
            flash[:success] = "#{@referral.referred_by.vname} successfully referred someone!"
            redirect_to user_path(@user)
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can set referrances!"
            else
               flash[:error] = "You have already set your referral!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Sets up the variables necessary to handle referrals
         logged_in = current_user
         referralFound = Referral.find_by_id(getReferralParams("Id"))
         validUsers = User.select{|user| user.pouch.privilege != "Bot" && user.pouch.privlege != "Glitchy" && user.pouch.privilege != "Trial" && (logged_in && referralFound && user.id != referralFound.user_id)}
         staff = (logged_in && referralFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))

         if(staff && validUsers.count > 0)
            @referral = referralFound
            @user = referralFound.user
            
            if(type == "update")
               #Saves the changes of the referral
               referrance = User.find_by_vname(params[:referral][:vname]).downcase
               referralFound.referred_by_id = referrance.id
               userMatch = validUsers.select{|user| user.id == referrance.id}
               
               #Eventually add a way for the player to earn points for the new one while subtracting points from the old one.
               
               
               if(userMatch)
                  @referral = referralFound
                  @referral.save
                  flash[:success] = "Referral for #{@referral.user.vname} was successfully updated!"
                  redirect_to referrals_path
               else
                  flash[:error] = "Invalid referrance selected. Please try again!"
                  redirected_on root_path
               end
            end
         else
            if(!referralFound)
               flash[:error] = "The referral does not exist!"
            elsif(!logged_in || !staff)
               flash[:error] = "This page is restricted to Staff only!"
            else
               flash[:error] = "The user list is currently empty!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         #Collects the user data needed to create a new mainplaylist
         logged_in = current_user
         validUsers = User.select{|user| user.pouch.privilege != "Bot" && user.pouch.privlege != "Glitchy" && user.pouch.privilege != "Trial" && (logged_in && user.id != logged_in.id)}
         userExists = Referral.select{|referral| logged_in && referral.user_id == logged_in.id}
         
         #Determines if the user has already set their referral status
         if(logged_in && validUsers.count > 0 && !userExists)
            newReferral = logged_in.referrals.new
            referrance = nil
            if(type == "create")
               referrance = User.find_by_vname(params[:referral][:vname]).downcase #Make this differe
               newReferral = logged_in.referrals.new(getReferralParams("Referral"))
               newReferral.created_on = currentTime
               newReferral.referred_by_id = referrance.id
               userMatch = validUsers.select{|user| user.id == referrance.id}
            end
            
            @referral = newReferral
            #@user = User.find_by_vname(logged_in.vname)
            
            if(type == "create")
               if(userMatch)
                  #Adds points to the referrance's pouch
                  @referral.save
                  referralpoints = Fieldcost.find_by_name("Referral")
                  referrance.pouch.amount += referralpoints.amount
                  @pouch = referrance.user.pouch
                  @pouch.save
                  
                  #Emails the user about the new referral
                  economyTransaction("Source", referralPoints.amount, referrance.id, "Points")
                  ContentMailer.content_created(@referral.user, "Referral", referralpoints.amount).deliver_now
                  flash[:success] = "User #{@referral.referred_by.vname} successfully referred someone!"
                  redirect_to user_path(logged_in)
               else
                  flash[:error] = "Invalid referrance selected. Please try again!"
                  redirected_on root_path
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can set referrances!"
            elsif(validUsers.count == 0)
               flash[:error] = "The user list is currently empty!"
            else
               flash[:error] = "You have already set your referral!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
            if(staff)
               if(type == "discover")
                  discoverpage
               else
                  createCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            if(type == "discover")
               discoverpage
            else
               createCommons(type)
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
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  allReferrals = Referral.order("created_on desc")
                  @referrals = Kaminari.paginate_array(allReferrals).page(getReferralParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create" || type == "discoveredit")
               #Login only
               callMaintenance(type)
            elsif(type == "edit" || type == "update")
               #Staff only
               editCommons(type)
            end
         end
      end
end
