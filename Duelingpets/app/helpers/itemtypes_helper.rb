module ItemtypesHelper

   private
      def getItemtypeParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "ItemtypeId")
            value = params[:itemtype_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Itemtype")
            value = params.require(:itemtype).permit(:name, :basecost, :dreyterriumcost)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def editCommons(type)
         logged_in = current_user
         itemtypeFound = Itemtype.find_by_id(getItemtypeParams("Id"))
         staff = (logged_in && itemtypeFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         if(staff)
            #Sets up a particular action that an item can perform
            @itemtype = itemtypeFound
            
            if(type == "update")
               #Saves the changes of the itemaction
               if(@itemtype.update_attributes(getItemtypeParams("Itemtype")))
                  flash[:success] = "Itemtype #{@itemtype.name} was successfully updated!"
                  redirect_to itemtypes_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @itemtype.destroy
               flash[:success] = "Itemtype #{itemtypeFound.name} action was succesfully removed!"
               redirect_to itemtypes_path
            end
         else
            if(!itemtypeFound)
               flash[:error] = "The itemtype does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         #Builds a new itemtype
         if(staff)
            newItemtype = Itemtype.new
            if(type == "create")
               newItemtype = Itemtype.new(getItemtypeParams("Itemtype"))
               newItemtype.created_on = currentTime
            end
            @itemtype = newItemtype
            if(type == "create")
               if(@itemtype.save)
                  flash[:success] = "Itemtype #{@itemtype.name} was successfully created!"
                  redirect_to itemtypes_path
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
                  allItemtypes = Itemtype.order("created_on desc")
                  @itemtypes = Kaminari.paginate_array(allItemtypes).page(getItemtypeParams("Page")).per(50)
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
