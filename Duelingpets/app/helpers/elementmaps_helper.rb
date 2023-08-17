module ElementmapsHelper

   private
      def getElementmapParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Elementchart")
            value = params[:elementchart_id]
         elsif(type == "Elementmap")
            value = params.require(:elementmap).permit(:element_id, :damageoffset_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def editCommons(type)
         #Staff and Elementmap owner
         logged_in = current_user
         elementmapFound = Elementmap.find_by_id(getElementmapParams("Id"))
         staff = (logged_in && elementmapFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         elementmapOwner = (logged_in && elementmapFound && logged_in.id == elementmapFound.user_id)
         
         if(staff || elementmapOwner)
            #elemementmapFound.updated_on = currentTime
            @elementmap = elementmapFound
            @elementchart = Elementchart.find_by_id(elementchartFound.user.vname)
            if(type == "update")
               if(@elementmap.update_attributes(getElementchartParams("Elementmap")))
                  flash[:success] = "Elementchart was successfully updated!"
                  redirect_to user_elementchart_path(@elementchart.user, @elementchart)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (elementchartOwner && elementchartFound.user.startgame)
               if(staff || owner)
                  @elementmap.destroy
                  flash[:success] = "Elementmap was successfully removed!"
                  if(staff)
                     redirect_to jukeboxes_list_path
                  else
                     redirect_to user_elementchart_path(elementmapFound.elementchart.user, elementmapFound.elementchart)
                  end
               else
                  flash[:error] = "Elementmap owner has not activated their game yet!"
                  redirect_to root_path
               end
            end
         else
            if(!elementmapFound)
               flash[:error] = "The elementmap does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this elementmap!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         shieldFound = Elementchart.find_by_id(getElementmapParams("Elementchart"))
         shieldOwner = (logged_in && shieldFound && logged_in.id == shieldFound.user_id)
         
         if(shieldOwner)
            newElementmap = shieldFound.elementmaps.new
            if(type == "create")
               newElementmap = shieldFound.elementmaps.new(getElementmapParams("Elementmap"))
            end
            @elementmap = newElementmap
            @elementchart = shieldFound
            
            #Two we can't have the same element appear multiple times unless
            #one is a power and the other is a weakness or a strength
            #Three we need to have a locking mechanism to prevent the player from adding more elements to the chart
            
            #Allows the user to choose the element and the damage offset to apply
            allElements = Element.order("reviewed_on", "created_on")
            @elements = allElements
            allDamageOffsets = Damageoffset.all #order("reviewed_on", "created_on")
            @damageoffsets = allDamageOffsets
            
            if(type == "create")
               if(@elementmap.save)
                  flash[:success] = "Elementmap was successfully created!"
                  redirect_to user_elementchart_path(@elementchart.user, @elementchart)
               else
                  render "new"
               end
            end
         else
            if(!shieldFound)
               flash[:error] = "The elementchart does not exist!"
            elsif(!logged_in || shieldFound.user_id != logged_in.id)
               flash[:error] = "Only the elementchart owner can create elementmaps!"
            #elsif(!userFound.gameinfo.startgame)
            #   flash[:error] = "User #{userFound.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(11)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
               if(type == "new" || type == "create")
                  createCommons(type)
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
            if(type == "new" || type == "create")
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
               #Staff only
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
               
               if(staff)
                  allElementmaps = Elementmap.all
                  @elementalmaps = allElementmaps.page(getElementmapParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
