module EquippeditemsHelper

   private
      def getEquipitemParams(type)
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
      
      def unequipItem
         logged_in = current_user
         equipitemFound = Equipitem.find_by_id(getEquipitemParams("Id"))
         owner = (logged_in && equipitemFound && logged_in.id == equipitem.equip.partner.user_id)
         
         #Unequips the item from the pet
         if(owner)
            flash[:success] = "Item #{equipitemFound.item.name} was unequipped from the pet!"
            redirect_to partner_equip_path(equipitemFound.equip.partner, equipitemFound.equip)
         else
            if(!equipitemFound)
               flash[:error] = "The equipitem does not exist!"
            else
               flash[:error] = "Only the equipitem owner can unequip items!"
            end
            redirect_to root_path
         end
      end

      def mode(type)
         if(timeExpired)
            logout_user
            redirect_to root_path
         else
            logoutExpiredUsers
            if(type == "index")
               #Staff only
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  allEquipitems = Equipitem.all
                  @equipitems = Kaminari.paginate_array(allEquipitems).page(getEquipitemParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "destroy")
               #Login only
               unequipItem
            end
         end
      end
end
