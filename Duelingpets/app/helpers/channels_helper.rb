module ChannelsHelper

   private
      def getChannelParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "ChannelId")
            value = params[:channel_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Channel")
            value = params.require(:channel).permit(:name, :description, :bookgroup_id, :privatechannel,
            :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache, :gviewer_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def channelValue(channelFound)
         #Will need revisions later for emeralds
         channel = Fieldcost.find_by_name("Channel")
         mainplaylist = Fieldcost.find_by_name("Mainplaylist")   
         subplaylist = Fieldcost.find_by_name("Subplaylist")
         movie = Fieldcost.find_by_name("Movie")
         allPlaylists = Subplaylist.all
         subplaylists = allPlaylists.select{|subplaylist| subplaylist.mainplaylist.channel_id == channelFound.id}
         allMovies = Movie.all
         movies = allMovies.select{|movie| movie.reviewed && movie.subplaylist.mainplaylist.channel_id == channelFound.id}
         points = (channel.amount + (channelFound.mainplaylists.count * mainplaylist.amount) + (subplaylists.count * subplaylist.amount) + (movies.count * movie.amount))
         return points
      end

      def displayVideo(channel, type)
         movie = nil

         #Displays the videos when the index page is open
         if(type == "index" && channel.mainplaylists.count > 0)
            mainplaylist = channel.mainplaylists.order("updated_on desc", "created_on desc").first
            subplaylist = mainplaylist.subplaylists.order("updated_on desc", "created_on desc").first
            if(mainplaylist.subplaylists.count > 0)
               movie = subplaylist.movies.order("updated_on desc", "created_on desc").first
            end
         end

         #Displays the videos when the show page is open
         if(type == "show" && channel.subplaylists.count > 0)
            subplaylist = channel.subplaylists.order("updated_on desc", "created_on desc").first
            movie = subplaylist.movies.order("updated_on desc", "created_on desc").first
         end

         #Displays the videos when the subplaylist is open
         if(type == "subplaylist" && channel.movies.count > 0)
            movie = channel.movies.order("updated_on desc", "created_on desc").first
         end

         #Displays the video when the movie is open
         if(type == "movie")
            movie = channel
         end
         return movie
      end

      #Redo this one later
      def getMovieCounts(mainplaylist)
         allMovies = Movie.all
         movies = allMovies.select{|movie| movie.reviewed && movie.subplaylist.mainplaylist_id == mainplaylist.id}
         return movies.count
      end

      #Redo this one later
      def getMainplaylistMusic(mainplaylist)
         allSubplaylists = mainplaylist.subplaylists.order("updated_on desc", "created_on desc")
         value = nil
         if(allSubplaylists.count > 0)
            subplaylists = allSubplaylists.select{|subplaylist| !subplaylist.privatesubplaylist}
            value = getSubplaylistMusic(subplaylists.first)
         end
         return value
      end
      
      def activateIntroVideo
         #Staff, channelOwner
         logged_in = current_user
         channelFound = Channel.find_by_name(getChannelParams("Id"))
         staff = (logged_in && channelFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         channelOwner = (logged_in && channelFound && logged_in.id == channelFound.user_id)
         if(staff || channelOwner)
            channelFound.toggle(:music_on)
            @channel = channelFound
            @channel.save
            if(staff)
               redirect_to channels_list_path
            else
               redirect_to user_channels_path(channelFound.user)
            end
         else
            if(!channelFound)
               flash[:error] = "The channel does not exist!"
            else
               flash[:error] = "User doesn't have permission to activate the music!"
            end
            redirect_to root_path
         end
      end
      
      def indexpage
         userFound = User.find_by_vname(getChannelParams("User"))
         if(userFound)
            userChannels = userFound.channels.order("updated_on desc", "created_on desc")
            channels = userChannels
            @user = userFound
         else
            allChannels = Channel.order("updated_on desc", "created_on desc")
            channels = allChannels
         end
         @channels = Kaminari.paginate_array(channels).page(getChannelParams("Page")).per(10)
      end

      def showpage
         #Staff, channelOwner and guests
         logged_in = current_user
         channelFound = Channel.find_by_name(getChannelParams("Id"))
         staff = (logged_in && channelFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         channelOwner = (logged_in && channelFound && logged_in.id == channelFound.user_id)
         guests = channelFound
         if(staff || channelOwner || guests)
            @channel = channelFound
            if(guests)
               #Only show the mainplaylists that the user can view
               mainplaylists = channelFound.mainplaylists.order("updated_on desc", "created_on desc") #.select{|playlist| checkBookgroupStatus(playlist)}
               @mainplaylists = Kaminari.paginate_array(mainplaylists).page(getChannelParams("Page")).per(10)
               
               #Finds the subplaylists that belong to the channel
               playlists = Subplaylist.select{|playlist| playlist.mainplaylist.channel_id = channelFound.id}#.select{|playlist| checkBookgroupStatus(playlist.mainplaylist) && playlist.mainplaylist.channel_id == channelFound.id}
               @subplaylists = playlists.count
               
               #Finds the movies that belong to the channel
               movies = Movie.select{|movie| movie.reviewed && movie.subplaylist.mainplaylist.channel_id == channelFound.id} #&& checkBookgroupStatus(movie) && checkBookgroupStatus(movie.subplaylist.mainplaylist) && movie.subplaylist.mainplaylist.channel_id == channelFound.id}
               @movies = movies.count
            else
               #Displays all the available mainplaylists for the owner and staff
               mainplaylists = channelFound.mainplaylists.order("updated_on desc", "created_on desc")
               @mainplaylists = Kaminari.paginate_array(mainplaylists).page(getChannelParams("Page")).per(10)
               
               #Finds the subplaylists that belong to the channel
               playlists = Subplaylist.select{|playlist| playlist.mainplaylist.channel_id == channelFound.id}
               @subplaylists = playlists.count
               
               #Finds the movies that belong to the channel
               movies = Movie.select{|movie| movie.subplaylist.mainplaylist.channel_id == channelFound.id}
               @movies = movies.count
            end
         else
            flash[:error] = "The channel does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Channel owner
         logged_in = current_user
         channelFound = Channel.find_by_name(getChannelParams("Id"))
         staff = (logged_in && channelFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         channelOwner = (logged_in && channelFound && logged_in.id == channelFound.user_id)
         if(staff || channelOwner)
            channelFound.updated_on = currentTime
            @channel = channelFound
            @user = User.find_by_vname(channelFound.user.vname)
            if(type == "update")
               if(@channel.update_attributes(getChannelParams("Channel")))
                  flash[:success] = "Channel #{@channel.name} was successfully updated!"
                  redirect_to user_channel_path(@channel.user, @channel)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (channelOwner && channelFound.user.startgame)
               if(staff || owner)
                  if(!staff)
                     points = (channelValue(channelFound) * 0.30).round
                     channelFound.user.pouch.amount += points
                     @pouch = channelFound.user.pouch
                     @pouch.save
                     economyTransaction("Source", points, channelFound.user.id, "Points")
                  end
                  @channel.destroy
                  flash[:success] = "Channel #{@channel.name} was successfully removed!"
                  if(staff)
                     redirect_to channels_list_path
                  else
                     redirect_to user_channels_path(channelFound.user)
                  end
               else
                  flash[:error] = "Channel owner #{channelFound.user.vname} has not activated their game yet!"
                  redirect_to root_path
               end
            end
         else
            if(!channelFound)
               flash[:error] = "The channel does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this channel!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         userFound = User.find_by_vname(getChannelParams("User"))
         owner = (logged_in && userFound && logged_in.id == userFound.id) #&& userFound.gameinfo.startgame)
         price = Fieldcost.find_by_name("Channel")
         if(owner) #&& userFound.pouch.amount - price.amount >= 0) #swap with emeralds later
            newChannel = logged_in.channels.new
            if(type == "create")
               newChannel = logged_in.channels.new(getChannelParams("Channel"))
               newChannel.created_on = currentTime
               newChannel.updated_on = currentTime
            end
            @channel = newChannel
            @user = userFound
            if(type == "create")
               if(@channel.save)
                  #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                  userFound.pouch.amount -= price.amount
                  @pouch = userFound.pouch
                  @pouch.save
                  
                  #Send the funds to the central bank
                  rate = Ratecost.find_by_name("Purchaserate")
                  tax = (price.amount * rate.amount)
                  hoard = Dragonhoard.find_by_id(1)
                  hoard.profit += tax
                  @hoard = hoard
                  @hoard.save
                  
                  #Keeps track of the economy
                  economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                  economyTransaction("Tax", tax, logged_in.id, "Points")
                  flash[:success] = "Channel #{@channel.name} was successfully created!"
                  redirect_to user_channel_path(@user, @channel)
               else
                  render "new"
               end
            end
         else
            if(!userFound)
               flash[:error] = "The user does not exist!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can create channels!"
            elsif(!userFound.gameinfo.startgame)
               flash[:error] = "User #{userFound.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{userFound.vname} can't afford the channel price!"
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
               if(type == "index")
                  indexpage
               elsif(type == "show")
                  showpage
               elsif(type == "music")
                  activateIntroVideo
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
            if(type == "index")
               indexpage
            elsif(type == "show")
               showpage
            elsif(type == "music")
               activateIntroVideo
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
               #Guests
               callMaintenance(type)
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy" || type == "music")
               #Login only
               callMaintenance(type)
            elsif(type == "list")
               #Staff only
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Reviewer"))
               if(staff)
                  allChannels = Channel.order("updated_on desc, created_on desc")
                  @channels = allChannels.page(getChannelParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
