module EntitytypesHelper

   private
      def getEntitytypeParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Entitytype")
            value = params.require(:entitytype).permit(:name)
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
            allEntitytypes = Entitytype.all
            @entitytypes = allEntitytypes.page(getEntitytypeParams("Page")).per(50)
         else
            flash[:error] = "This page is restricted to Staff only!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         entitytypeFound = Entitytype.find_by_id(getEntitytypeParams("Id"))
         staff = logged_in && entitytypeFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(staff)
            @entitytype = entitytypeFound
            
            if(type == "update")
               if(@entitytype.update_attributes(getEntitytypeParams("Entitytype")))
                  flash[:success] = "Entity #{@entitytype.name} was successfully updated!"
                  redirect_to entitytypes_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @entitytype.destroy
               flash[:success] = "Entity #{entitytypeFound.name} was successfully removed!"
               redirect_to entitytypes_path
            end
         else
            if(!entitytypeFound)
               flash[:error] = "The entitytype does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(staff)
            newEntityType = entitytype.new
            if(type == "create")
               newEntityType = Entitytype.new(getEntitytypeParams("Entitytype"))
            end
            
            @entitytype = newEntityType
            
            if(type == "create")
               if(@entitytype.save)
                  flash[:success] = "Entity #{@entitytype.name} was successfully created!"
                  redirect_to entitytypes_path
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
               indexpage
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
