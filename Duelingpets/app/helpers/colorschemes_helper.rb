module ColorschemesHelper

   private
      def getColorParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "ColorId")
            value = params[:color_id]
         elsif(type == "Colorscheme") #Requires a revamp for this part
            value = params.require(:colorscheme).permit(:name, :description, :image, :nightcolor, :backgroundcolor, 
            :headercolor, :subheader1color, :subheader2color, :subheader3color, :textcolor,
            :editbuttoncolor, :editbuttonbackgcolor,
            :destroybuttoncolor, :destroybuttonbackgcolor, :submitbuttoncolor, :submitbuttonbackgcolor,
            :navigationcolor, :navigationlinkcolor, :navigationhovercolor, :navigationhoverbackgcolor,
            :onlinestatuscolor, :profilecolor, :profilehovercolor,
            :profilehoverbackgcolor, :sessioncolor, :navlinkcolor, :navlinkhovercolor,
            :navlinkhoverbackgcolor, :explanationborder, :explanationbackgcolor, :explanheadercolor,
            :explantextcolor, :errorfieldcolor, :errorcolor, :warningcolor, :notificationcolor,
            :successcolor)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def colorOwner
         userFound = User.find_by_vname(getColorParams("User"))
         value = "Colorscheme List"
         if(userFound)
            value = (userFound.vname + "'s colorschemes")
         end
         return value
      end

      def indexpage
         userFound = User.find_by_vname(getColorParams("User"))
         if(userFound)
            userPatterns = userFound.colorschemes.order("updated_on desc, created_on desc")
            patterns = userPatterns
            @user = userFound
         else
            allPatterns = Colorscheme.order("updated_on desc, created_on desc")
            patterns = allPatterns
         end
         staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Keymaster"))
         validColors = patterns.select{|pattern| pattern.activated || staff || current_user && pattern.user_id == current_user.id}
         @colorschemes = Kaminari.paginate_array(validColors).page(getColorParams("Page")).per(10)
      end
      
      def showpage
         #Staff, palletOwner and guests
         logged_in = current_user
         colorschemeFound = Colorscheme.find_by_id(getColorParams("Id"))
         staff = (logged_in && colorschemeFound && (logged_in.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         palletOwner = (logged_in && colorschemeFound && logged_in.id == colorschemeFound.user_id)
         guests = colorschemeFound
         if(staff || palletOwner || guests)
            @colorscheme = colorschemeFound
         else
            flash[:error] = "Colorscheme not found!"
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff and Colorscheme owner
         logged_in = current_user
         patternFound = Colorscheme.find_by_name(getColorschemeParams("Id"))
         staff = (logged_in && patternFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         patternOwner = (logged_in && patternFound && logged_in == patternFound.user_id)
         if(staff || patternOwner)
            patternFound.updated_on = currentTime
            @colorscheme = patternFound
            @user = User.find_by_vname(patternFound.user.vname)
            if(type == "update")
               if(@colorscheme.update_attributes(getColorParams("Colorscheme")))
                  flash[:success] = "Colorscheme #{@colorscheme.name} was successfully updated."
                  redirect_to user_colorschemes_path(colorschemeFound.user)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (patternOwner && patternOwnerFound.user.startgame)
               mandatoryColor = ((patternFound.id == 1 && patternFound.id == 2) || patternFound.democolor)
               if((staff || owner) && !mandatoryColor)
                  if(!staff)
                     price = Fieldcost.find_by_name("Colorschemecleanup")
                     if(patternFound.user.pouch.amount - price.amount >= 0)
                        patternFound.user.pouch.amount -= price.amount
                        @pouch = patternFound.user.pouch
                        @pouch.save
                        economyTransaction("Sink", price.amount, patternFound.user.id, "Points")
                        validRemove = true
                     end
                  end
                  if(staff || validRemove)
                     #Revert all users that used that particular color pattern
                     #If this doesn't work then change these to selects and perform manual assignments
                     #.each do |info| color = 1
                     #@userinfo = info, @userinfo.save
                     dayUsers = Userinfo.all.map!{|info| daycolor_id == patternFound.id ? 1 : daycolor_id}
                     nightUsers = Userinfo.all.map!{|info| nightcolor_id == patternFound.id ? 2 : nightcolor_id}
                     flash[:success] = "Colorscheme #{@colorscheme.name} was successfully removed."
                     @colorscheme.destroy
                     if(staff)
                        redirect_to colorschemes_list_path
                     else
                        redirect_to user_colorschemes_path(colorschemeFound.user)
                     end
                  else
                     flash[:error] = "Pattern owner #{patternFound.user.vname} can't afford the colorscheme removal price!"
                     redirect_to root_path
                  end
               else
                  if(!patternOwnerFound.user.startgame)
                     flash[:error] = "Pattern owner #{patternFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "The user can't remove a mandatory color pattern!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!patternFound)
               flash[:error] = "The color pattern does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this color pattern!"
            end
            redirect_to root_path
         end
      end      

      def createCommons(type)
         logged_in = current_user
         userFound = User.find_by_vname(getColorParams("User"))
         owner = (logged_in && logged_in.id == userFound.id && userFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Colorscheme")
         if(owner && user.pouch.amount - price.amount >= 0)
            newColorscheme = logged_in.colorschemes.new
            if(type == "create")
               newColorscheme = logged_in.colorschemes.new(getColorParams("Colorscheme"))
               newColorscheme.created_on = currentTime
            end
            @user = userFound
            @colorscheme = newColorscheme
            if(type == "create")
               if(@colorscheme.save)
                  logged_in.pouch.amount -= price.amount
                  @pouch = logged_in.pouch
                  @pouch.save
                  
                  #Send the funds to the central bank
                  rate = Ratecost.find_by_name("Purchaserate")
                  tax = (price.amount * rate.amount)
                  hoard = Dragonhoard.find_by_id(1)
                  hoard.profit += tax
                  @hoard = hoard
                  @hoard.save
                  
                  #Keeps track of the economy
                  economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                  economyTransaction("Tax", tax, logged_in.id, "Points")
                  ContentMailer.content_created(@colorscheme, "Colorscheme", price.amount).deliver_later(wait: 5.minutes)
                  flash[:success] = "Colorscheme #{@colorscheme.name} was successfully created."
                  redirect_to colorschemes_path
               else
                  render "new"
               end
            end
         else
            if(!userFound)
               flash[:error] = "The user does not exist!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can create colorschemes!"
            elsif(!userFound.gameinfo.startgame)
               flash[:error] = "User #{userFound.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{userFound.vname} can't afford the colorscheme price!"
            end
            redirect_to root_path
         end
      end

      def colorChanger(type)
         logged_in = current_user
         userFound = User.find_by_id(getColorParams("User"))
         staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Keymaster"))
         if(logged_in && userFound && (staff || logged_in.id == userFound.id))
            if(type == "undo")
               userFound.userinfo.daycolor_id = 1
               userFound.userinfo.nightcolor_id = 2
               @userinfo = userFound.userinfo
               @userinfo.save
               flash[:success] = "#{userFound.vname}'s color pattern was reverted!"
               if(staff) #Keymaster maybe
                  redirect_to users_path
               else
                  redirect_to user_path(logged_in)
               end
            else
               colorFound = Colorscheme.find_by_id(getColorParams("ColorId"))
               if(colorFound && (staff || logged_in.id == userFound.id))
                  colorFound.toggle(:activated)
                  @colorFound = colorFound
                  @colorFound.save
                  if(staff)
                     redirect_to colorschemes_list_path
                  else
                     redirect_to colorschemes_path
                  end
               else
                  flash[:error] = "Colorscheme does not exist!"
                  redirect_to root_path
               end
            end
         else
            if(!userFound)
               flash[:error] = "The user does not exist!"
            else
               flash[:error] = "User doesn't have permission to change the color pattern!"
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
               if(type == "index")
                  indexpage
               elsif(type == "show")
                  showpage
               elsif(type == "undo" || type == "activatecolor")
                  colorChanger(type)
               elsif(type == "new" || type == "create")
                  createCommons(type)
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/bookworlds/maintenance"
               end
            end
         else
            if(type == "index")
               indexpage
            elsif(type == "show")
               showpage
            elsif(type == "undo" || type == "activatecolor")
               colorChanger(type)
            elsif(type == "new" || type == "create")
               createCommons(type)
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
               #Guest
               callMaintenance(type)
            elsif(type == "show")
               #Guest
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "undo" || type == "activatecolor")
               #Login only
               callMaintenance(type)
            elsif(type == "list")
               #Staff only
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Reviewer"))
               if(staff)
                  allColors = Colorscheme.order("updated_on desc, created_on desc")
                  @colorschemes = Kaminari.paginate_array(allColors).page(getColorParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
