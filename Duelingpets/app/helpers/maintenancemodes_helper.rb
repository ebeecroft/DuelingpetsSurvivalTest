module MaintenancemodesHelper

   private
      def getMaintenanceParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Maintenancemode")
            value = params.require(:maintenancemode).permit(:name, :maintenance_on)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def editCommons(type)
         logged_in = current_user
         maintenancemodeFound = Maintenancemode.find_by_id(getMaintenancemodeParams("Id"))
         staff = (logged_in && maintenancemodeFound && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         if(staff)
            @maintenancemode = maintenancemodeFound
            if(type == "update")
               if(@maintenancemode.update_attributes(getMaintenancemodeParams("Maintenancemode")))
                  flash[:success] = "Maintenancemode #{@maintenancemode.name} was successfully updated!"
                  redirect_to maintenancemodes_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @maintenancemode.destroy
               flash[:success] = "Maintenancemode #{maintenancemodeFound.name} was successfully removed!"
               redirect_to maintenancemodes_path
            end
         else
            if(!maintenancemodeFound)
               flash[:error] = "The maintenancemode does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this maintenancemode!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         if(staff)
            newMaintenancemode = Maintenancemode.new
            if(type == "create")
               newMaintenancemode = Maintenancemode.new(getMaintenancemodeParams("Maintenancemode"))
               newMaintenancemode.created_on = currentTime
            end
            @maintenancemode = newMaintenancemode
            if(type == "create")
               if(@maintenancemode.save)
                  flash[:success] = "Maintenancemode #{@maintenancemode.name} was successfully created!"
                  redirect_to maintnenancemodes_path
               else
                  render "new"
               end
            end
         else
            flash[:error] = "This page is restricted to Staff only!"
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
                  allMaintenancemodes = Maintenancemode.order("created_on desc")
                  @maintenancemodes = Kaminari.paginate_array(allMaintenancemodes).page(getMaintenancemodeParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create")
               #Staff only
               createCommons(type)
            elsif(type == "edit" || type == "update" || type == "destroy")
               #Staff only
               editCommons(type)
            end
         end
      end
end
