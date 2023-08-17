module UserinfosHelper

   private
      def getUserinfoParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Userinfo")
            value = params.require(:userinfo).permit(:avatar, :remote_avatar_url, :avatar_cache, :miniavatar,
            :remote_miniavatar_url, :miniavatar_cache, :ogg, :remote_ogg_url, :ogg_cache, :info, :daycolor_id, :nightcolor_id, :bookgroup_id, :audiobrowser, :videobrowser, :nightvision, :militarytime)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def profileInfo(type, user)
         info = ""
         if(type == "Birthday")
            if(current_user && (current_user.pouch.privilege == "Admin" || current_user.id == user.id))
               info = user.birthday.strftime("%B-%d-%Y")
            else
               info = user.birthday.strftime("%B-%d")
            end
         elsif(type == "Vname")
            if(current_user)
               info = user.vname + " joined on: " + user.joined_on.strftime("%B-%d-%Y")
            else
               info = user.vname
            end
         end
         return info
      end

      def editCommons(type)
         #Staff and Userinfo owner
         logged_in = current_user
         infoFound = Userinfo.find_by_id(getUserinfoParams("Id"))
         staff = (logged_in && infoFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         owner = (logged_in && infoFound && logged_in.id == infoFound.user_id)
         
         if(staff || owner)
            #Creates a list of day and night pallets
            nightPallets = Colorscheme.select{|pallet| (pallet.activated || staff || owner) && pallet.nightcolor}
            dayPallets = Colorscheme.select{|pallet| (pallet.activated || staff || owner) && !pallet.nightcolor}
            @nightcolors = nightPallets
            @daycolors = dayPallets
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @userinfo = infoFound
            
            if(type == "update")
               if(@userinfo.update_attributes(getUserinfoParams("Userinfo")))
                  flash[:success] = "Userinfo for #{@userinfo.user.vname} was successfully updated!"
                  if(staff)
                     redirect_to userinfos_path
                  else
                     redirect_to user_path(@userinfo.user)
                  end
               else
                  render "edit"
               end
            end
         else
            if(!infoFound)
               flash[:error] = "The userinfo does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit the userinfo!"
            end
            redirect_to root_path
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
                  allInfos = Userinfo.order("id desc")
                  @userinfos = Kaminari.paginate_array(allInfos).page(getUserinfoParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "edit" || type == "update")
               #Login only
               editCommons(type)
            end
         end
      end
end
