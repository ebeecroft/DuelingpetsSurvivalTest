module ItemactionsHelper

   private
      def getItemactionParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Itemaction")
            value = params.require(:itemaction).permit(:name)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def editCommons(type)
         logged_in = current_user
         itemactionFound = Itemaction.find_by_id(getItemactionParams("Id"))
         staff = (logged_in && itemactionFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         if(staff)
            #Sets up a particular action that an item can perform
            @itemaction = itemactionFound
            
            if(type == "update")
               #Saves the changes of the itemaction
               if(@itemaction.update_attributes(getItemactionParams("Itemaction")))
                  flash[:success] = "Itemaction #{@itemaction.name} was successfully updated!"
                  redirect_to itemactions_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @itemaction.destroy
               flash[:success] = "Itemaction #{itemactionFound.name} action was succesfully removed!"
               redirect_to itemactions_path
            end
         else
            if(!itemactionFound)
               flash[:error] = "The itemaction does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         #Builds a new itemaction for items
         if(staff)
            newAction = Itemaction.new
            if(type == "create")
               newAction = Itemaction.new(getItemactionParams("Itemaction"))
               newAction.created_on = currentTime
            end
            @itemaction = newAction
            if(type == "create")
               if(@itemaction.save)
                  flash[:success] = "Itemaction #{@itemaction.name} was successfully created!"
                  redirect_to itemactions_path
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
                  allItemactions = Itemaction.order("created_on desc")
                  @itemactions = Kaminari.paginate_array(allItemactions).page(getItemactionParams("Page")).per(50)
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
