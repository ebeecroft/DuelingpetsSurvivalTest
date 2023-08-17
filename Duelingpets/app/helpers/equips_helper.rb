module EquipsHelper

   private
      def getEquipParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
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
                  allEquips = Equip.order("id desc")
                  @equips = Kaminari.paginate_array(allEquips).page(getEquipParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Login only
               logged_in = current_user
               equipFound = Equip.find_by_id(getEquipParams("Id"))
               equipOwner = (logged_in && equipFound && logged_in.id == equipFound.partner.user_id)
               
               #Displays the equipment for the owner 
               if(equipOwner)
                  @equip = equipFound
                  #slots = @equip.equipslots.all #Needs to be remade
                  #@equipslots = Kaminari.paginate_array(slots).page(getEquipParams("Page")).per(1)
               else
                  if(!equipFound)
                     flash[:error] = "The equip does not exist!"
                  else
                     flash[:error] = "Only the owner of the equipment can view this section!"
                  end
                  redirect_to root_path
               end
            end
         end
      end
end
