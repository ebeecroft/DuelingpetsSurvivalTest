module MainsheetsHelper

   private
      def getMainsheetParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Jukebox")
            value = params[:jukebox_id]
         elsif(type == "Mainsheet")
            value = params.require(:mainsheet).permit(:title, :description)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateJukebox(jukebox)
         jukebox.updated_on = currentTime
         @jukebox = jukebox
         @jukebox.save
      end

      def getSubsheetMusic(subsheet) #Is this still necessary?
         allSounds = subsheet.sounds.order("updated_on desc", "reviewed_on desc")
         sounds = allSounds.select{|sound| sound.reviewed && checkBookgroupStatus(sound)}
         return sounds.first
      end

      def showpage
         #Staff, mainsheetOwner and guests
         logged_in = current_user
         mainsheetFound = Mainsheet.find_by_id(getMainsheetParams("Id"))
         staff = (logged_in && mainsheetFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainsheetOwner = (logged_in && mainsheetFound && logged_in.id == mainsheetFound.user_id)
         guests = mainsheetFound #&& checkBookgroupStatus(mainsheetFound)
         if(staff || mainsheetOwner || guests)
            @mainsheet = mainsheetFound
            if(guests)
               #Only show the subsheets that the user can view? This might get revised later as it might not make sense.
               sheets = Subsheet.order("updated_on desc", "created_on desc").select{|sheet| sheet.mainsheet_id == mainsheetFound.id}
               @subsheets = Kaminari.paginate_array(sheets).page(getMainsheetParams("Page")).per(10)
               
               #Finds the sounds that belong to the mainsheet
               sounds = Sound.select{|sound| sound.reviewed && sound.subsheet.mainsheet_id == mainsheetFound.id} #&& checkBookgroupStatus(sound) && sound.subsheet.mainsheet_id == mainsheetFound.id}
               @sounds = sounds.count
            else
               #Displays all the available subsheets for the owner and staff
               sheets = mainsheetFound.subsheets.oder("updated_on desc", "created_on desc")
               @subsheets = Kaminari.paginate_array(sheets).page(getMainsheetParams("Page")).per(10)
               
               #Finds the sounds that belong to the mainsheet
               sounds = Sound.select{|sound| sound.subsheet.mainsheet_id == mainsheetFound.id}
               @sounds = sounds.count
            end
         else
            if(!mainsheetFound)
               flash[:error] = "The mainsheet does not exist!"
            else
               flash[:error] = "The user does not have access to view this mainsheet!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Mainsheet owner
         logged_in = current_user
         mainsheetFound = Mainsheet.find_by_id(getMainsheetParams("Id"))
         staff = (logged_in && mainsheetFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainsheetOwner = (logged_in && mainsheetFound && logged_in.id == mainsheetFound.user_id)
         
         if(staff || mainsheetOwner)
            mainsheetFound.updated_on = currentTime
            @mainsheet = mainsheetFound
            @jukebox = Jukebox.find_by_name(mainsheetFound.jukebox.name)
            if(type == "update")
               if(@mainsheet.update_attributes(getMainsheetParams("Mainsheet")))
                  flash[:success] = "Mainsheet #{@mainsheet.name} was successfully updated!"
                  updateJukebox(@mainsheet.jukebox)
                  redirect_to jukebox_mainsheet_path(@mainsheet.jukebox, @mainsheet)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (mainsheetOwner && mainsheetFound.user.startgame)
               price = Fieldcost.find_by_name("Mainsheetcleanup")
               if(staff || owner && mainsheetFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     mainsheetFound.user.pouch.amount -= price.amount
                     @pouch = mainsheetFound.user.pouch.amount
                     @pouch.save
                     updateJukebox(mainsheetFound.jukebox)
                     economyTransaction("Sink", price.amount, mainsheetFound.user.id, "Points")
                  end
                  @mainsheet.destroy
                  flash[:success] = "Mainsheet #{@mainsheet.name} was successfully removed!"
                  if(staff)
                     redirect_to mainsheets_path
                  else
                     redirect_to user_jukebox_path(mainsheetFound.jukebox.user, mainsheetFound.jukebox)
                  end
               else
                  if(!mainsheetFound.user.startgame)
                     flash[:error] = "Mainsheet owner #{mainsheetFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Mainsheet owner #{mainsheetFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!mainsheetFound)
               flash[:error] = "The mainsheet does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this mainsheet!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new mainsheet
         logged_in = current_user
         jukeboxFound = Jukebox.find_by_name(getMainsheetParams("Jukebox"))
         owner = (logged_in && jukeboxFound && logged_in.id == jukeboxFound.user_id) #&& jukeboxFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Mainsheet")
         freeFolder = (logged_in.jukeboxes.count == 1 && jukeboxFound.mainsheets.count == 0)
         
         if(owner) #&& freeFolder || logged_in.pouch.amount - price.amount >= 0) #swap with emeralds later
            newMainsheet = jukeboxFound.mainsheets.new
            if(type == "create")
               #Builds a new mainsheet for the user
               newMainsheet = jukeboxFound.mainsheets.new(getMainsheetParams("Mainsheet"))
               newMainsheet.created_on = currentTime
               newMainsheet.updated_on = currentTime
               newMainsheet.user_id = logged_in.id
            end
            
            @mainsheet = newMainsheet
            @jukebox = jukeboxFound
            
            if(type == "create")
               if(@mainsheet.save)
                  if(!freeFolder)
                     #Deducts the charges from the player's purse
                     #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                     #logged_in.pouch.amount -= price.amount #Emeralds might be added later for this section
                     #@pouch = logged_in.pouch
                     #@pouch.save
                  
                     #Central bank collects taxes from the creation of a new mainplaylist
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save

                     #Creates transactions for the newly created mainsheet
                     #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Mainsheet #{@mainsheet.name} was successfully created!"
                  updateJukebox(@mainsheet.jukebox)
                  redirect_to jukebox_mainsheet_path(@jukebox, @mainsheet)
               else
                  render "new"
               end
            end
         else
            if(!jukeboxFound)
               flash[:error] = "The jukebox does not exist!"
            elsif(!logged_in || logged_in.id != jukeboxFound.user_id)
               flash[:error] = "Only the jukebox owner can create mainsheets!"
            elsif(!jukeboxFound.user.gameinfo.startgame)
               flash[:error] = "Jukebox owner #{jukeboxFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Jukebox owner #{jukeboxFound.user.vname} can't afford the mainsheet price!"
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
                  allMainsheets = Mainsheet.order("updated_on desc, created_on desc")
                  @mainsheets = allMainsheets.page(getMainsheetParams("Page")).per(10)
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
