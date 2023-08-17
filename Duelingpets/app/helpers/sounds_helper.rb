module SoundsHelper

   private
      def getSoundParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
          elsif(type == "SoundId")
            value = params[:sound_id]
         elsif(type == "Subsheet")
            value = params[:subsheet_id]
         elsif(type == "Sound")
            value = params.require(:sound).permit(:title, :description, :bookgroup_id, :song)#:ogg, :remote_ogg_url, :ogg_cache,
            #:mp3, :remote_mp3_url, :mp3_cache, :bookgroup_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateJukebox(subsheet)
         subsheet.updated_on = currentTime
         @subsheet = subsheet
         @subsheet.save
         mainsheet = Mainsheet.find_by_id(@subsheet.mainsheet_id)
         mainsheet.updated_on = currentTime
         @mainsheet = mainsheet
         @mainsheet.save
         jukebox = Jukebox.find_by_id(@mainsheet.jukebox_id)
         jukebox.updated_on = currentTime
         @jukebox = jukebox
         @jukebox.save
      end

      def showpage
         #Staff, jukeboxOwner, soundOwner and guests
         logged_in = current_user
         soundFound = Sound.find_by_id(getSoundParams("Id"))
         staff = (logged_in && soundFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         soundOwner = (logged_in && soundFound && logged_in.id == soundFound.user_id)
         jukeboxOwner = (logged_in && soundFound && logged_in.id == soundFound.subsheet.mainsheet.jukebox.user_id)
         guests = soundFound #&& checkBookgroupStatus(soundFound)
         
         if(staff || jukeboxOwner || soundOwner || guests)
            @sound = soundFound
         else
            if(!soundFound)
               flash[:error] = "The sound does not exist!"
            #elsif(!checkBookgroupStatus(soundFound))
            #   flash[:error] = "This content is restricted to higher bookgroups!"
            else
               flash[:error] = "The user does not have access to view this sound!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, Jukebox owner and Sound owner
         logged_in = current_user
         soundFound = Sound.find_by_id(getSoundParams("Id"))
         staff = (logged_in && soundFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         soundOwner = (logged_in && soundFound && logged_in.id == soundFound.user_id)
         jukeboxOwner = (logged_in && soundFound && logged_in.id == soundFound.subsheet.mainsheet.jukebox.user_id)
         
         if(staff || jukeboxOwner || soundOwner)
            soundFound.updated_on = currentTime
            soundFound.reviewed = false
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @sound = soundFound
            @subsheet = Subsheet.find_by_id(soundFound.subsheet.id)
            if(type == "update")
               if(@sound.update_attributes(getSoundParams("Sound")))
                  flash[:success] = "Sound #{@sound.name} was successfully updated!"
                  updateJukebox(@sound.subsheet)
                  redirect_to subsheet_sound_path(@sound.subsheet, @sound)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (soundOwner && soundFound.user.startgame && soundFound.user.pouch.amount - price.amount >= 0)
               jOwner = (jukeboxOwner && logged_in.startgame && logged_in.pouch.amount - price.amount >= 0)
               price = Fieldcost.find_by_name("Soundcleanup")
               
               if(staff || jOwner || owner)
                  if(!staff)
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch.amount
                     @pouch.save
                     updateJukebox(soundFound.subsheet)
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @sound.destroy
                  flash[:success] = "Sound #{@sound.name} was successfully removed!"
                  if(staff)
                     redirect_to sounds_path
                  else
                     redirect_to mainsheet_subsheet_path(soundFound.subsheet.mainsheet, soundFound.subsheet)
                  end
               else
                  if(logged_in.startgame)
                     flash[:error] = "Jukebox owner #{logged_in.vname} has not activated their game yet!"
                  elsif(!movieFound.user.startgame)
                     flash[:error] = "Sound owner #{soundFound.user.vname} has not activated their game yet!"
                  elsif(logged_in.pouch.amount - price.amount < 0)
                     flash[:error] = "Jukebox owner #{logged_in.user.vname} can't afford the removal price!"
                  else
                     flash[:error] = "Sound owner #{soundFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!soundFound)
               flash[:error] = "The sound does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this sound!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new mainsheet
         logged_in = current_user
         subsheetFound = Subsheet.find_by_id(getSoundParams("Subsheet"))
         owner = (logged_in && subsheetFound && logged_in.id == subsheetFound.user_id) #&& subsheetFound.user.gameinfo.startgame)
         guests = (logged_in && subsheetFound && subsheetFound.collab_mode) #&& checkBookgroupStatus(subsheetFound.mainsheet.jukebox) && logged_in.gameinfo.startgame)
         subsheet = (subsheetFound && !subsheetFound.fave_folder)
         
         #price = Fieldcost.find_by_name("Mainplaylist")
         #freeFolder = (logged_in.channels.count == 1 && channelFound.mainplaylists.count == 0)
         if(subsheet && (owner || guests))
            newSound = subsheetFound.sounds.new
            if(type == "create")
               #Builds a new sound for the user
               newSound = subsheetFound.sounds.new(getSoundParams("Sound"))
               newSound.created_on = currentTime
               newSound.updated_on = currentTime
               newSound.user_id = logged_in.id
            end
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @sound = newSound
            @subsheet = subsheetFound
            
            if(type == "create")
               if(@sound.save)
                  #Sets up the tag for sounds
                  soundtag = Soundtag.new(params[:soundtag]) #Will be rebuilt
                  soundtag.sound_id = @sound.id
                  soundtag.tag1_id = 1
                  @soundtag = soundtag
                  @soundtag.save
                  
                  #Returns the user to the show view of the new sound
                  updateJukebox(@sound.subsheet)
                  url = "http://www.duelingpets.net/sounds/review"
                  ContentMailer.content_review(@sound, "Sound", url).deliver_now
                  flash[:success] = "Sound works" #"Sound #{@sound.name} was successfully created!"
                  redirect_to subsheet_sound_path(@subsheet, @sound)
               else
                  render "new"
               end
            end
         else
            if(!subsheetFound)
               flash[:error] = "The subsheet does not exist!"
            elsif(!subsheet)
               flash[:error] = "Favorite folders can't have sounds directly uploaded to the subsheet!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can upload sounds to this subsheet!"
            elsif(!subsheetFound.collab_mode && logged_in.id != subsheetFound.user_id)
               flash[:error] = "This subsheet is not open for collaboration!"
            #elsif(!checkBookgroupStatus(subsheetFound.mainsheet))
            #   flash[:error] = "This content is restricted to higher bookgroups!"
            elsif(!subsheetFound.user.gameinfo.startgame)
               flash[:error] = "Subsheet owner #{subsheetFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Guest #{logged_in.vname} has not activated their game yet!"
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
               logged_in == current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
               
               if(staff)
                  allSounds = Sound.order("updated_on desc, created_on desc")
                  @sounds = Kaminari.paginate_array(allSounds).page(getSoundParams("Page")).per(30)
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
                  allSounds = Sound.order("reviewed_on desc, created_on desc")
                  soundsToReview = allSounds.select{|sound| !sound.reviewed}
                  @sounds = Kaminari.paginate_array(soundsToReview).page(getSoundParams("Page")).per(30)
               elsif(staff && type == "approve")
                  soundFound = Sound.find_by_id(getSoundParams("SoundId"))
                  if(soundFound) #&& (soundFound.points_earned || soundFound.user.gameinfo.startgame))
                     #Updates the review stats of the approved sound
                     soundFound.reviewed_on = currentTime
                     soundFound.reviewed = true
                     updateJukebox(soundFound.subsheet)
                     
                     points = 0
                     #if(!soundFound.points_earned) #Support giving sound owner some points later
                        #Adds the points to the user's pouch
                    #    soundpoints = Fieldcost.find_by_name("Sound")
                    #    points = soundpoints.amount
                    #    pouch = Pouch.find_by_user_id(soundFound.user_id)
                    #    pouch.amount += points
                    #    @pouch = pouch
                    #    @pouch.save
                    #    soundFound.points_earned = true
                    #    economyTransaction("Source", points, soundFound.user.id, "Points")
                    # end
                     
                     #Lets the user know that their sound has been approved
                     @sound = soundFound
                     @sound.save
                     ContentMailer.content_approved(@sound, "Sound", points).deliver_now
                     flash[:success] = "User #{@sound.user.vname}'s sound #{@sound.title} was approved!"
                     redirect_to sounds_review_path
                  else
                     if(!soundFound)
                        flash[:error] = "Sound does not exist!"
                     else
                        flash[:error] = "User {soundFound.user.vname} has not activated their game yet!"
                     end
                     redirect_to root_path
                  end
               elsif(staff && type == "deny")
                  soundFound = Sound.find_by_id(getSoundParams("SoundId"))
                  if(soundFound)
                     @sound = soundFound
                     ContentMailer.content_denied(@sound, "Sound").deliver_now
                     flash[:success] = "User #{@sound.user.vname}'s sound #{@sound.name} was denied!" #Make this name later
                     redirect_to sounds_review_path
                  else
                     flash[:error] = "Sound does not exist!"
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
