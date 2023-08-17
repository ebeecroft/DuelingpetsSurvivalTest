module TraittypesHelper

   private
      def getTraittypeParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Traittype")
            value = params.require(:traittype).permit(:name)
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
            allTraittypes = Traittype.all
            @traittypes = allTraittypes.page(getTraittypeParams("Page")).per(50)
         else
            flash[:error] = "This page is restricted to Staff only!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         traittypeFound = Traittype.find_by_id(getTraittypeParams("Id"))
         staff = logged_in && traittypeFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(staff)
            @traittype = traittypeFound
            
            if(type == "update")
               if(@traittype.update_attributes(getTraittypeParams("Traittype")))
                  flash[:success] = "Trait #{@traittype.name} was successfully updated!"
                  redirect_to traittypes_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @traittype.destroy
               flash[:success] = "Trait #{traittypeFound.name} was successfully removed!"
               redirect_to traittypes_path
            end
         else
            if(!traittypeFound)
               flash[:error] = "The traittype does not exist!"
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
            newTraitType = Traittype.new
            if(type == "create")
               newTraitType = Traittype.new(getTraittypeParams("Traittype"))
            end
            
            @traittype = newTraittype
            
            if(type == "create")
               if(@traittype.save)
                  flash[:success] = "Trait #{@traittype.name} was successfully created!"
                  redirect_to traittypes_path
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
