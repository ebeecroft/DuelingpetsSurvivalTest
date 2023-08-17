module MainplaylistsHelper

   private
      def getMainplaylistParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Channel")
            value = params[:channel_id]
         elsif(type == "Mainplaylist")
            value = params.require(:mainplaylist).permit(:title, :description)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateChannel(channel)
         channel.updated_on = currentTime
         @channel = channel
         @channel.save
      end

      def getSubplaylistMusic(subplaylist) #Is this still necessary?
         allMovies = subplaylist.movies.order("updated_on desc", "reviewed_on desc")
         movies = allMovies.select{|movie| movie.reviewed && checkBookgroupStatus(movie)}
         return movies.first
      end

      def showpage
         #Staff, mainfolderOwner and guests
         logged_in = current_user
         mainplaylistFound = Mainplaylist.find_by_id(getMainplaylistParams("Id"))
         staff = (logged_in && mainplaylistFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainplaylistOwner = (logged_in && mainplaylistFound && logged_in.id == mainplaylistFound.user_id)
         guests = mainplaylistFound #&& checkBookgroupStatus(mainplaylistFound)
         if(staff || mainplaylistOwner || guests)
            @mainplaylist = mainplaylistFound
            if(guests)
               #Only show the subplaylists that the user can view? This might get revised later as it might not make sense.
               playlists = Subplaylist.order("updated_on desc", "created_on desc").select{|playlist| playlist.mainplaylist_id == mainplaylistFound.id}
               @subplaylists = Kaminari.paginate_array(playlists).page(getMainplaylistParams("Page")).per(10)
               
               #Finds the movies that belong to the mainplaylist
               movies = Movie.select{|movie| movie.subplaylist.mainplaylist_id == mainplaylistFound.id}#.select{|movie| movie.reviewed && checkBookgroupStatus(movie) && movie.subplaylist.mainplaylist_id == mainplaylistFound.id}
               @movies = movies.count
            else
               #Displays all the available subplaylists for the owner and staff
               playlists = mainplaylistFound.subplaylists.order("updated_on desc", "created_on desc")
               @subplaylists = Kaminari.paginate_array(playlists).page(getMainplaylistParams("Page")).per(10)
               
               #Finds the movies that belong to the mainplaylist
               movies = Movie.select{|movie| movie.subplaylist.mainplaylist_id == mainplaylistFound.id}
               @movies = movies.count
            end
         else
            if(!mainplaylistFound)
               flash[:error] = "The mainplaylist does not exist!"
            else
               flash[:error] = "The user does not have access to view this mainplaylist!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Mainplaylist owner
         logged_in = current_user
         mainplaylistFound = Mainplaylist.find_by_id(getMainplaylistParams("Id"))
         staff = (logged_in && mainplaylistFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainfolderOwner = (logged_in && mainplaylistFound && logged_in.id == mainplaylistFound.user_id)
         
         if(staff || mainplaylistOwner)
            mainplaylistFound.updated_on = currentTime
            @mainplaylist = mainplaylistFound
            @channel = Channel.find_by_name(mainplaylistFound.channel.name)
            if(type == "update")
               if(@mainplaylist.update_attributes(getMainplaylistParams("Mainplaylist")))
                  flash[:success] = "Mainplaylist #{@mainplaylist.name} was successfully updated!"
                  updateChannel(@mainplaylist.channel)
                  redirect_to channel_mainplaylist_path(@mainplaylist.channel, @mainplaylist)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (mainplaylistOwner && mainplaylistFound.user.startgame)
               price = Fieldcost.find_by_name("Mainplaylistcleanup")
               if(staff || owner && mainplaylistFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     mainplaylistFound.user.pouch.amount -= price.amount
                     @pouch = mainplaylistFound.user.pouch.amount
                     @pouch.save
                     updateChannel(mainplaylistFound.channel)
                     economyTransaction("Sink", price.amount, mainplaylistFound.user.id, "Points")
                  end
                  @mainplaylist.destroy
                  flash[:success] = "Mainplaylist #{@mainplaylist.name} was successfully removed!"
                  if(staff)
                     redirect_to mainplaylists_path
                  else
                     redirect_to user_channel_path(mainplaylistFound.channel.user, mainplaylistFound.channel)
                  end
               else
                  if(!mainplaylistFound.user.startgame)
                     flash[:error] = "Mainplaylist owner #{mainplaylistFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Mainplaylist owner #{mainplaylistFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!mainplaylistFound)
               flash[:error] = "The mainplaylist does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this mainplaylist!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new mainplaylist
         logged_in = current_user
         channelFound = Channel.find_by_name(getMainplaylistParams("Channel"))
         owner = (logged_in && channelFound && logged_in.id == channelFound.user_id) #&& channelFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Mainplaylist")
         freeFolder = (logged_in.channels.count == 1 && channelFound.mainplaylists.count == 0)
         
         if(owner) #&& freeFolder || logged_in.pouch.amount - price.amount >= 0) #swap with emeralds later
            newMainplaylist = channelFound.mainplaylists.new
            if(type == "create")
               #Builds a new mainplaylist for the user
               newMainplaylist = channelFound.mainplaylists.new(getMainplaylistParams("Mainplaylist"))
               newMainplaylist.created_on = currentTime
               newMainplaylist.updated_on = currentTime
               newMainplaylist.user_id = logged_in.id
            end
            
            @mainplaylist = newMainplaylist
            @channel = channelFound
            
            if(type == "create")
               if(@mainplaylist.save)
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

                     #Creates transactions for the newly created mainplaylist
                     #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Mainplaylist #{@mainplaylist.name} was successfully created!"
                  updateChannel(@mainplaylist.channel)
                  redirect_to channel_mainplaylist_path(@channel, @mainplaylist)
               else
                  render "new"
               end
            end
         else
            if(!channelFound)
               flash[:error] = "The channel does not exist!"
            elsif(!logged_in || logged_in.id != channelFound.user_id)
               flash[:error] = "Only the channel owner can create mainplaylists!"
            elsif(!channelFound.user.gameinfo.startgame)
               flash[:error] = "Channel owner #{channelFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Channel owner #{channelFound.user.vname} can't afford the mainplaylist price!"
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
                  allMainplaylists = Mainplaylist.order("updated_on desc, created_on desc")
                  @mainplaylists = allMainplaylists.page(getMainplaylistParams("Page")).per(10)
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
