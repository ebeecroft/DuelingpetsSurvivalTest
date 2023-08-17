module MoviesHelper

   private
      def getMovieParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
          elsif(type == "MovieId")
            value = params[:movie_id]
         elsif(type == "Subplaylist")
            value = params[:subplaylist_id]
         elsif(type == "Movie")
            value = params.require(:movie).permit(:title, :description, :bookgroup_id, :clip, :thumbnail)
            #value = params.require(:movie).permit(:title, :description, :ogv, :remote_ogv_url, :ogv_cache,
            #:mp4, :remote_mp4_url, :mp4_cache, :bookgroup_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateChannel(subplaylist)
         subplaylist.updated_on = currentTime
         @subplaylist = subplaylist
         @subplaylist.save
         mainplaylist = Mainplaylist.find_by_id(@subplaylist.mainplaylist_id)
         mainplaylist.updated_on = currentTime
         @mainplaylist = mainplaylist
         @mainplaylist.save
         channel = Channel.find_by_id(@mainplaylist.channel_id)
         channel.updated_on = currentTime
         @channel = channel
         @channel.save
      end
      
      def showpage
         #Staff, channelOwner, movieOwner and guests
         logged_in = current_user
         movieFound = Movie.find_by_id(getMovieParams("Id"))
         staff = (logged_in && movieFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         movieOwner = (logged_in && movieFound && logged_in.id == movieFound.user_id)
         channelOwner = (logged_in && movieFound && logged_in.id == movieFound.subplaylist.mainplaylist.channel.user_id)
         guests = movieFound #&& checkBookgroupStatus(movieFound)
         
         if(staff || channelOwner || movieOwner || guests)
            @movie = movieFound
         else
            if(!movieFound)
               flash[:error] = "The movie does not exist!"
            #elsif(!checkBookgroupStatus(movieFound))
            #   flash[:error] = "This content is restricted to higher bookgroups!"
            else
               flash[:error] = "The user does not have access to view this mainplaylist!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, Channel owner and Movie owner
         logged_in = current_user
         movieFound = Movie.find_by_id(getMovieParams("Id"))
         staff = (logged_in && movieFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         movieOwner = (logged_in && movieFound && logged_in.id == movieFound.user_id)
         channelOwner = (logged_in && movieFound && logged_in.id == movieFound.subplaylist.mainplaylist.channel.user_id)
         
         if(staff || channelOwner || movieOwner)
            movieFound.updated_on = currentTime
            movieFound.reviewed = false
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @movie = movieFound
            @subplaylist = Subplaylist.find_by_id(movieFound.subplaylist.id)
            if(type == "update")
               if(@movie.update_attributes(getMovieParams("Movie")))
                  flash[:success] = "Movie #{@movie.name} was successfully updated!"
                  updateChannel(@movie.subplaylist)
                  redirect_to subplaylist_movie_path(@movie.subplaylist, @movie)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("Moviecleanup")
               owner = (movieOwner && movieFound.user.startgame && movieFound.user.pouch.amount - price.amount >= 0)
               cOwner = (channelOwner && logged_in.startgame && logged_in.pouch.amount - price.amount >= 0)
               if(staff || cOwner || owner)
                  if(!staff)
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch.amount
                     @pouch.save
                     updateChannel(movieFound.subplaylist)
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @movie.destroy
                  flash[:success] = "Movie #{@movie.name} was successfully removed!"
                  if(staff)
                     redirect_to movies_path
                  else
                     redirect_to mainplaylist_subplaylist_path(movieFound.subplaylist.mainplaylist, movieFound.subplaylist)
                  end
               else
                  if(!logged_in.gameinfo.startgame)
                     flash[:error] = "Channel owner #{logged_in.vname} has not activated their game yet!"
                  elsif(!movieFound.user.startgame)
                     flash[:error] = "Movie owner #{movieFound.user.vname} has not activated their game yet!"
                  elsif(logged_in.pouch.amount - price.amount < 0)
                     flash[:error] = "Channel owner #{logged_in.user.vname} can't afford the removal price!"
                  else
                     flash[:error] = "Movie owner #{movieFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!movieFound)
               flash[:error] = "The movie does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this movie!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         #Collects the user data needed to create a new mainplaylist
         logged_in = current_user
         subplaylistFound = Subplaylist.find_by_id(getMovieParams("Subplaylist"))
         owner = (logged_in && subplaylistFound && logged_in.id == subplaylistFound.user_id) #&& subplaylistFound.user.gameinfo.startgame)
         guests = (logged_in && subplaylistFound && subplaylistFound.collab_mode) #&& checkBookgroupStatus(subplaylistFound.mainplaylist.channel) && logged_in.gameinfo.startgame)
         subfolder = (subplaylistFound && !subplaylistFound.fave_folder)
         
         #price = Fieldcost.find_by_name("Mainplaylist")
         #freeFolder = (logged_in.channels.count == 1 && channelFound.mainplaylists.count == 0)
         if(subfolder && (owner || guests))
            newMovie = subplaylistFound.movies.new
            if(type == "create")
               #Builds a new movie for the user
               newMovie = subplaylistFound.movies.new(getMovieParams("Movie"))
               newMovie.created_on = currentTime
               newMovie.updated_on = currentTime
               newMovie.user_id = logged_in.id
            end
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @movie = newMovie
            @subplaylist = subplaylistFound
            
            if(type == "create")
               if(@movie.save)
                  #Sets up the tag for movies
                  movietag = Movietag.new(params[:movietag]) #Will be rebuilt
                  movietag.movie_id = @movie.id
                  movietag.tag1_id = 1
                  @movietag = movietag
                  @movietag.save
                  
                  #Returns the user to the show view of the new movie
                  updateChannel(@movie.subplaylist)
                  url = "http://www.duelingpets.net/movies/review"
                  ContentMailer.content_review(@movie, "Movie", url).deliver_now
                  flash[:success] = "Movie #{@movie.title} was successfully created!"
                  redirect_to subplaylist_movie_path(@subplaylist, @movie)
               else
                  render "new"
               end
            end
         else
            if(!subplaylistFound)
               flash[:error] = "The subplaylist does not exist!"
            elsif(!subfolder)
               flash[:error] = "Favorite folders can't have movies directly uploaded to the subplaylist!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can upload movies to this subfolder!"
            elsif(!subplaylistFound.collab_mode && logged_in.id != subplaylistFound.user_id)
               flash[:error] = "This subplaylist is not open for collaboration!"
            #elsif(!checkBookgroupStatus(subplaylistFound.mainplaylist))
            #   flash[:error] = "This content is restricted to higher bookgroups!"
            elsif(!subplaylistFound.user.gameinfo.startgame)
               flash[:error] = "Subplaylist owner #{subplaylistFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Guest #{logged_in.vname} has not activated their game yet!"
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
                  allMovies = Movie.order("updated_on desc, created_on desc")
                  @movies = Kaminari.paginate_array(allMovies).page(getMovieParams("Page")).per(30)
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
            elsif(type == "review" || type == "approve" || type == "deny")
               #Staff only
               staff = (current_user && current_user.pouch.privilege == "Admin" || current_user.pouch.privilegge == "Keymaster" || current_user.pouch.privilege == "Reviewer")
               if(staff && type == "review")
                  allMovies = Movie.order("reviewed_on desc, created_on desc")
                  moviesToReview = allMovies.select{|movie| !movie.reviewed}
                  @movies = Kaminari.paginate_array(moviesToReview).page(getMovieParams("Page")).per(30)
               elsif(staff && type == "approve")
                  movieFound = Movie.find_by_id(getMovieParams("MovieId"))
                  if(movieFound) #&& (movieFound.points_earned || movieFound.user.gameinfo.startgame))
                     #Updates the review stats of the approved movie
                     movieFound.reviewed_on = currentTime
                     movieFound.reviewed = true
                     updateChannel(movieFound.subplaylist)
                     
                     points = 0
                     #if(!movieFound.points_earned) #Support giving movie owner some points later
                        #Adds the points to the user's pouch
                        moviepoints = Fieldcost.find_by_name("Movie")
                        points = moviepoints.amount
                        pouch = Pouch.find_by_user_id(movieFound.user_id)
                        pouch.amount += points
                        @pouch = pouch
                        @pouch.save
                        #movieFound.points_earned = true
                        #economyTransaction("Source", points, movieFound.user.id, "Points")
                     #end
                     
                     #Lets the user know that their movie has been approved
                     @movie = movieFound
                     @movie.save
                     ContentMailer.content_approved(@movie, "Movie", points).deliver_now
                     flash[:success] = "User #{@movie.user.vname}'s movie #{@movie.title} was approved!"
                     redirect_to movies_review_path
                  else
                     if(!movieFound)
                        flash[:error] = "Movie does not exist!"
                     else
                        flash[:error] = "User {movieFound.user.vname} has not activated their game yet!"
                     end
                     redirect_to root_path
                  end
               elsif(staff && type == "deny")
                  movieFound = Movie.find_by_id(getMovieParams("MovieId"))
                  if(movieFound)
                     @movie = movieFound
                     ContentMailer.content_denied(@movie, "Movie").deliver_now
                     flash[:success] = "User #{@movie.user.vname}'s movie #{@movie.title} was denied!" #Make this name later
                     redirect_to movies_review_path
                  else
                     flash[:error] = "Movie does not exist!"
                     redirect_to root_path
                  end
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
