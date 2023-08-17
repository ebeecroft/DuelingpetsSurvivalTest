module SubsheetsHelper

   private
      def getSubsheetParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Mainsheet")
            value = params[:mainsheet_id]
         elsif(type == "Subsheet")
            value = params.require(:subsheet).permit(:title, :description, :collab_mode, :fave_folder, :privatesubsheet)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateJukebox(mainsheet)
         mainsheet.updated_on = currentTime
         @mainsheet = mainsheet
         @mainsheet.save
         jukebox = Jukebox.find_by_id(@mainsheet.jukebox_id)
         jukebox.updated_on = currentTime
         @jukebox = jukebox
         @jukebox.save
      end

      def showpage
         #Staff, Subsheet owner and Guests
         logged_in = current_user
         subsheetFound = Subsheet.find_by_id(getSubsheetParams("Id"))
         staff = (logged_in && subsheetFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subsheetOwner = (logged_in && subsheetFound && logged_in.id == subsheetFound.user_id)
         guests = subsheetFound #&& checkBookgroupStatus(subsheetFound)
         
         if(staff || subsheetOwner || guests)
            @subsheet = subsheetFound
            if(guests)
               #Finds the sounds that belong to the subsheet
               sounds = subsheetFound.sounds.order("updated_on desc", "created_on desc")#.select{|sound| sound.reviewed} #&& checkBookgroupStatus(sound)}
               @sounds = Kaminari.paginate_array(sounds).page(getSubsheetParams("Page")).per(30)
            else
               #Finds the sounds that belong to the subsheet
               sounds = subsheetFound.sounds.order("updated_on desc", "created_on desc")
               @sounds = Kaminari.paginate_array(sounds).page(getSubsheetParams("Page")).per(30)
            end
         else
            if(!subsheetFound)
               flash[:error] = "The subsheet does not exist!"
            else
               flash[:error] = "The user does not have access to view this sheet!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Subsheet owner
         logged_in = current_user
         subsheetFound = Subsheet.find_by_id(getSubsheetParams("Id"))
         staff = (logged_in && subsheetFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subsheetOwner = (logged_in && subsheetFound && logged_in.id == subsheetFound.user_id)
         
         if(staff || subsheetOwner)
            subsheetFound.updated_on = currentTime
            @subsheet = subsheetFound
            @mainsheet = Mainsheet.find_by_id(subsheetFound.mainsheet_id)
            if(type == "update")
               if(@subsheet.update_attributes(getSubsheetParams("Subsheet")))
                  flash[:success] = "Subsheet #{@subsheet.name} was successfully updated!"
                  updateJukebox(@subsheet.mainsheet)
                  redirect_to mainsheet_subsheet_path(@subsheet.mainsheet, @subsheet)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (subsheetOwner && subsheetFound.user.startgame)
               price = Fieldcost.find_by_name("Subsheetcleanup")
               if(staff || owner && subsheetFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     subsheetFound.user.pouch.amount -= price.amount
                     @pouch = subsheetFound.user.pouch.amount
                     @pouch.save
                     updateJukebox(subsheetFound.mainsheet)
                     economyTransaction("Sink", price.amount, subsheetFound.user.id, "Points")
                  end
                  @subsheet.destroy
                  flash[:success] = "Subsheet #{subsheetFound.name} was successfully removed!"
                  if(staff)
                     redirect_to subsheets_path
                  else
                     redirect_to jukebox_mainsheet_path(subsheetFound.mainsheet.jukebox, subsheetFound.mainsheet)
                  end
               else
                  if(!subsheetFound.user.startgame)
                     flash[:error] = "Subsheet owner #{subsheetFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Subsheet owner #{subsheetFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!subsheetFound)
               flash[:error] = "The subsheet does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this subsheet!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new subsheet
         logged_in = current_user
         mainsheetFound = Mainsheet.find_by_id(getSubsheetParams("Mainsheet"))
         owner = (logged_in && mainsheetFound && logged_in.id == mainsheetFound.user_id) #&& mainsheetFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Subsheet")
         freeFolder = (logged_in.jukeboxes.count == 1 && logged_in.mainsheets.count == 1 && mainsheetFound.subsheets.count == 0)
         
         if(owner) #&& freeFolder || logged_in.pouch.amount - price.amount >= 0) #swap with emeralds later
            newSubsheet = mainsheetFound.subsheets.new
            if(type == "create")
               #Builds a new subsheet for the user
               newSubsheet = mainsheetFound.subsheets.new(getSubsheetParams("Subsheet"))
               newSubsheet.created_on = currentTime
               newSubsheet.updated_on = currentTime
               newSubsheet.user_id = logged_in.id
            end

            @subsheet = newSubsheet
            @mainsheet = mainsheetFound
            
            if(type == "create")
               if(@subsheet.save)
                  if(!freeFolder)
                     #Deducts the charges from the player's purse
                     #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                     #logged_in.pouch.amount -= price.amount #Emeralds might be added later for this section
                     #@pouch = logged_in.pouch
                     #@pouch.save
                  
                     #Central bank collects taxes from the creation of a new subsheet
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save

                     #Creates transactions for the newly created subsheet
                     #economyTransaction("Sink", price.amount, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Subsheet #{@subsheet.name} was successfully created!"
                  updateJukebox(@subsheet.mainsheet)
                  redirect_to mainsheet_subsheet_path(@mainsheet, @subsheet)
               else
                  render "new"
               end
            end
         else
            if(!mainsheetFound)
               flash[:error] = "The mainsheet does not exist!"
            elsif(!logged_in || logged_in.id != mainsheetFound.user_id)
               flash[:error] = "Only the mainsheet owner can create subsheets!"
            elsif(!mainsheetFound.user.gameinfo.startgame)
               flash[:error] = "Mainsheet owner #{mainsheetFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Mainsheet owner #{mainsheetFound.user.vname} can't afford the subsheet price!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         jukeboxMode = Maintenancemode.find_by_id(11)
         if(allMode.maintenance_on || jukeboxMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
               if(type == "show")
                  showpage
               elsif(type == "new" || type == "create")
                  createCommons(type)
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/jukeboxes/maintenance"
               end
            end
         else
            if(type == "show")
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
               #Staff only
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
               
               if(staff)
                  allSubsheets = Subsheet.order("updated_on desc, created_on desc")
                  @subsheets = allSubsheets.page(getSubsheetParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
