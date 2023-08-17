module TraitmapsHelper

   private
      def getTraitmapParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Traitmap")
            value = params.require(:traitmap).permit(:traittype_id, :amount)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def indexpage
         logged_in = current_user
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(staff)
            allTraitmaps = Traitmap.all
            @traitmaps = allTraitmaps.page(getTraitmapParams("Page")).per(50)
         else
            flash[:error] = "This page is restricted to Staff only!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         traitmapFound = Traitmap.find_by_id(getTraitmapParams("Id"))
         staff = logged_in && traitmapFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(logged_in)
            @traitmap = traitmapFound
            
            if(type == "update")
               if(@traitmap.update_attributes(getTraitmapParams("Traitmap")))
                  flash[:success] = "Traitmap was successfully updated!"
                  redirect_to entitytypes_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @traitmap.destroy
               flash[:success] = "Traitmap was successfully removed!"
               redirect_to traitmaps_path
            end
         else
            if(!traitmapFound)
               flash[:error] = "The traitmap does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         #Creature_id and the entitytype
         entitytype = params[:traitmap][:entitytype_id]
         entity_id = params[:traitmap][:entity_id]
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         #if(entitytype == 1)
         #   creatureFound = Creature.find_by_id(entity_id)
         #elsif(entitytype == 2)
         #   monsterFound = Monster.find_by_id(entity_id)
         #end
         #raise "Entity id is #{params[:traitmap][:entity_id]} and Entitytype id is #{params[:traitmap][:entitytype_id]}"
         entityFound = nil
         if(entitytype == 1)
            entityFound = Creature.find_by_id(entity_id)
         else
            entityFound = Monster.find_by_id(entity_id)
         end
         
         if(logged_in && entityFound)
            newTraitMap = Traitmap.new
            if(type == "create")
               #raise "I work here"
               newTraitMap = Traitmap.new(getTraitmapParams("Traitmap"))
               #raise "Trait id is: #{newTraitMap.traittype_id}"
               newTraitMap.entity_id = entity_id
               newTraitMap.entitytype_id = entitytype
            end
            
            @traitmap = newTraitMap
            
            if(type == "create")
               #raise "I work here"
               if(@traitmap.save)
                  flash[:success] = "Traitmap was successfully created!"
                  redirect_to root_path
                  #if(entitytype == 1)
                  #   redirect_to user_creature_path(entityFound.user, entityFound)
                  #elsif(entitytype == 2)
                  #   redirect_to user_monster_path(entityFound.user, entityFound)
                  #end
               else
                  render "new"
               end
            end
         else
            flash[:error] = "Only logged in users can create new traits!"
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #Setups the maintenance modes for the traitmap
         allMode = Maintenancemode.find_by_id(1)
         galleryMode = Maintenancemode.find_by_id(14)
         staff = current_user && current_user.pouch.privilege == "Admin"
         #staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
         maintenanceActive = (allMode.maintenance_on || galleryMode.maintenance_on)
         
         #Displays the features to the users if the maintenance is not active
         if(staff || !maintenanceActive)
            if(type == "new" || type == "create")
               createCommons(type)
            else
               editCommons(type)
            end
         else
            if(allMode.maintenance_on)
               render "/start/maintenance"
            else
               render "/galleries/maintenance"
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
               indexpage
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
