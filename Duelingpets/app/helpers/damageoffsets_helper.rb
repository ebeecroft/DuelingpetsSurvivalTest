module DamageoffsetsHelper

   private
      def getDamageoffsetParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "DamageoffsetId")
            value = params[:damageoffset_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Damageoffset")
            value = params.require(:damageoffset).permit(:name, :value)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      #def getElementName(element_id)
      #   value = Element.find_by_element_id(element_id)
      #   return value.name
      #end
      
      def indexpage
         #userFound = User.find_by_vname(getElementParams("User"))
         #if(userFound)
         #   userElements = userFound.elements.order("updated_on desc", "created_on desc")
         #   elements = userElements
         #   @user = userFound
         #else
            allDamageoffsets = Damageoffset.all #order("updated_on desc", "created_on desc")
            damageoffsets = allDamageoffsets
         #end
         @damageoffsets = Kaminari.paginate_array(damageoffsets).page(getDamageoffsetParams("Page")).per(10)
      end

      def showpage
         damageoffsetFound = Damageoffset.find_by_id(getDamageoffsetParams("Id"))
         if(damageoffsetFound) #&& (elementFound.reviewed || current_user && ((elementFound.user_id == current_user.id) || current_user.pouch.privilege == "Admin")))
            #removeTransactions
            #visitTimer(type, blogFound)
            #cleanupOldVisits
            @element = elementFound
         else
            if(!elementFound)
               flash[:error] = "Element doesn't exist!"
            elsif(!elementFound.reviewed)
               flash[:error] = "Element is not accessible to guests!"
            else
               flash[:error] = "User doesn't have permission to view this element!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Element owner
         logged_in = current_user
         damageoffsetFound = Damageoffset.find_by_id(getDamageoffsetParams("Id"))
         staff = (logged_in && damageoffsetFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         damageoffsetOwner = (logged_in && damageoffsetFound)# && logged_in.id == elementFound.user_id)
         
         if(staff || damageoffsetOwner)
            #elementFound.updated_on = currentTime
            #elementFound.reviewed = false
            @damageoffset = damageoffsetFound
            #@user = User.find_by_vname(elementFound.user.vname)
            if(type == "update")
               if(@damageoffset.update_attributes(getDamageoffsetParams("Damageoffset")))
                  flash[:success] = "Damageoffset was successfully updated!"
                  #redirect_to user_element_path(@element.user, @element)
                  redirect_to root_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               #price = Fieldcost.find_by_name("Elementcleanup")
               owner = (damageoffsetOwner) #&& elementFound.user.gameinfo.startgame && elementFound.user.pouch.amount - price.amount >= 0)
               if(staff || owner)
                  if(!staff)
                     #elementFound.user.pouch.amount -= price.amount #Remember to come back later to change to emeralds
                     #@pouch = elementFound.user.pouch
                     #@pouch.save
                     #economyTransaction("Sink", price.amount, elementFound.user.id, "Points")
                  end
                  @damageoffset.destroy
                  flash[:success] = "Damageoffset was successfully removed!"
                  if(staff)
                     #redirect_to elements_list_path
                     redirect_to root_path
                  else
                     #redirect_to user_elements_path(elementFound.user)
                     redirect_to root_path
                  end
               else
                  flash[:error] = "This section is currently being rebuilt and so it is probably very buggy!"
                  #if(!elementFound.user.gameinfo.startgame)
                  #   flash[:error] = "Element owner #{elementFound.user.vname} has not activated their game yet!"
                  #else
                  #   flash[:error] = "Element owner #{elementFound.user.vname} can't afford the removal price!"
                  #end
                  redirect_to root_path
               end
            end
         else
            if(!damageoffsetFound)
               flash[:error] = "The damageoffset does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this damageoffset!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         #userFound = User.find_by_vname(getDamageoffsetParams("User"))
         #validCreator = (logged_in && userFound && logged_in.id == userFound.id)
         validCreator = logged_in
         if(validCreator)
            #price = Fieldcost.find_by_name("Element")
            
            #Create the element if the user can afford the buildprice
            #if(logged_in.gameinfo.startgame && logged_in.pouch.amount - price.amount >= 0)
               newDamageoffset = Damageoffset.new
               if(type == "create")
                  newDamageoffset = Damageoffset.new(getDamageoffsetParams("Damageoffset"))
                  #newDamageoffset.created_on = currentTime
                  #newDamageoffset.updated_on = currentTime
               end
               @damageoffset = newDamageoffset
               #@user = userFound
               if(type == "create")
                  if(@damageoffset.save)
                     #url = "http://www.duelingpets.net/elements/review"
                     #ContentMailer.content_review(@element, "Element", url).deliver_now
                     flash[:success] = "Damageoffset #{@damageoffset.name} was successfully created!"
                     redirect_to damageoffsets_path
                  else
                     render "new"
                  end
               end
            #else
            #   if(!logged_in.gameinfo.startgame)
            #      flash[:error] = "{logged_in.vname} has not activated their game yet!"
            #   else
            #      flash[:error] = "#{logged_in.vname} can't afford the element buildprice!"
            #   end
            #   redirect_to root_path
            #end
         else
            flash[:error] = "The information you entered was invalid!"
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         elementMode = Maintenancemode.find_by_id(10)
         if(allMode.maintenance_on || elementMode.maintenance_on)
            if(current_user && current_user.pouch.privilege == "Admin")
               if(type == "index")
                  indexpage
               elsif(type == "show")
                  showpage
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/elements/maintenance"
               end
            end
         else
            if(type == "index")
               indexpage
            elsif(type == "show")
               showpage
            elsif(type == "new" || type == "create")
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
               #Guest Accessible
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "show")
               #Guest Accessible
               callMaintenance(type)
            end
         end
      end
end
