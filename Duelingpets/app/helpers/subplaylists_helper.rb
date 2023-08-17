module SubplaylistsHelper

   private
      def getSubplaylistParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Mainplaylist")
            value = params[:mainplaylist_id]
         elsif(type == "Subplaylist")
            value = params.require(:subplaylist).permit(:title, :description, :collab_mode, :fave_folder, :privatesubsheet)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateChannel(mainplaylist)
         mainplaylist.updated_on = currentTime
         @mainplaylist = mainplaylist
         @mainplaylist.save
         channel = Channel.find_by_id(@mainplaylist.channel_id)
         channel.updated_on = currentTime
         @channel = channel
         @channel.save
      end

      def showpage
         #Staff, Subplaylist owner and Guests
         logged_in = current_user
         subplaylistFound = Subplaylist.find_by_id(getSubplaylistParams("Id"))
         staff = (logged_in && subplaylistFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subplaylistOwner = (logged_in && subplaylistFound && logged_in.id == subplaylistFound.user_id)
         guests = subplaylistFound #&& checkBookgroupStatus(subplaylistFound)
         
         if(staff || subplaylistOwner || guests)
            @subplaylist = subplaylistFound
            if(guests)
               #Finds the movies that belong to the subplaylist
               movies = subplaylistFound.movies.order("updated_on desc", "created_on desc") #.select{|movie| movie.reviewed #&& checkBookgroupStatus(movie)}
               @movies = Kaminari.paginate_array(movies).page(getSubplaylistParams("Page")).per(30)
            else
               #Finds the movies that belong to the subplaylist
               movies = subplaylistFound.movies.order("updated_on desc", "created_on desc")
               @movies = Kaminari.paginate_array(movies).page(getSubplaylistParams("Page")).per(30)
            end
         else
            if(!subplaylistFound)
               flash[:error] = "The subplaylist does not exist!"
            else
               flash[:error] = "The user does not have access to view this playlist!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Subplaylist owner
         logged_in = current_user
         subplaylistFound = Subplaylist.find_by_id(getSubplaylistParams("Id"))
         staff = (logged_in && subplaylistFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subplaylistOwner = (logged_in && subplaylistFound && logged_in.id == subplaylistFound.user_id)
         
         if(staff || subplaylistOwner)
            subplaylistFound.updated_on = currentTime
            @subplaylist = subplaylistFound
            @mainplaylist = Mainplaylist.find_by_id(subplaylistFound.mainplaylist_id)
            if(type == "update")
               if(@subplaylist.update_attributes(getSubplaylistParams("Subplaylist")))
                  flash[:success] = "Subplaylist #{@subplaylist.name} was successfully updated!"
                  updateGallery(@subplaylist.mainplaylist)
                  redirect_to mainplaylist_subplaylist_path(@subplaylist.mainplaylist, @subplaylist)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (subplaylistOwner && subplaylistFound.user.startgame)
               price = Fieldcost.find_by_name("Subplaylistcleanup")
               if(staff || owner && subplaylistFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     subplaylistFound.user.pouch.amount -= price.amount
                     @pouch = subplaylistFound.user.pouch.amount
                     @pouch.save
                     updateChannel(subplaylistFound.mainplaylist)
                     economyTransaction("Sink", price.amount, subplaylistFound.user.id, "Points")
                  end
                  @subplaylist.destroy
                  flash[:success] = "Subplaylist #{subplaylistFound.name} was successfully removed!"
                  if(staff)
                     redirect_to subplaylists_path
                  else
                     redirect_to channel_mainplaylist_path(subplaylistFound.mainplaylist.channel, subplaylistFound.mainplaylist)
                  end
               else
                  if(!subplaylistFound.user.startgame)
                     flash[:error] = "Subplaylist owner #{subplaylistFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Subplaylist owner #{subplaylistFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!subplaylistFound)
               flash[:error] = "The subplaylist does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this subplaylist!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new subplaylist
         logged_in = current_user
         mainplaylistFound = Mainplaylist.find_by_id(getSubplaylistParams("Mainplaylist"))
         owner = (logged_in && mainplaylistFound && logged_in.id == mainplaylistFound.user_id) #&& mainplaylistFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Subplaylist")
         freeFolder = (logged_in.channels.count == 1 && logged_in.mainplaylists.count == 1 && mainplaylistFound.subplaylists.count == 0)
         
         if(owner) #&& freeFolder || logged_in.pouch.amount - price.amount >= 0) #swap with emeralds later
            newSubplaylist = mainplaylistFound.subplaylists.new
            if(type == "create")
               #Builds a new subplaylist for the user
               newSubplaylist = mainplaylistFound.subplaylists.new(getSubplaylistParams("Subplaylist"))
               newSubplaylist.created_on = currentTime
               newSubplaylist.updated_on = currentTime
               newSubplaylist.user_id = logged_in.id
            end

            @subplaylist = newSubplaylist
            @mainplaylist = mainplaylistFound
            
            if(type == "create")
               if(@subplaylist.save)
                  if(!freeFolder)
                     #Deducts the charges from the player's purse
                     #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                     #logged_in.pouch.amount -= price.amount #Emeralds might be added later for this section
                     #@pouch = logged_in.pouch
                     #@pouch.save
                  
                     #Central bank collects taxes from the creation of a new subplaylist
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save

                     #Creates transactions for the newly created subplaylist
                     #economyTransaction("Sink", price.amount, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Subplaylist #{@subplaylist.name} was successfully created!"
                  updateChannel(@subplaylist.mainplaylist)
                  redirect_to mainplaylist_subplaylist_path(@mainplaylist, @subplaylist)
               else
                  render "new"
               end
            end
         else
            if(!mainplaylistFound)
               flash[:error] = "The mainplaylist does not exist!"
            elsif(!logged_in || logged_in.id != mainplaylistFound.user_id)
               flash[:error] = "Only the mainplaylist owner can create subplaylists!"
            elsif(!mainplaylistFound.user.gameinfo.startgame)
               flash[:error] = "Mainplaylist owner #{mainplaylistFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Mainplaylist owner #{mainplaylistFound.user.vname} can't afford the subplaylist price!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         channelMode = Maintenancemode.find_by_id(13)
         if(allMode.maintenance_on || channelMode.maintenance_on)
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
                  render "/channels/maintenance"
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
                  allSubplaylists = Subplaylist.order("updated_on desc, created_on desc")
                  @subplaylists = allSubplaylists.page(getSubplaylistParams("Page")).per(30)
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
