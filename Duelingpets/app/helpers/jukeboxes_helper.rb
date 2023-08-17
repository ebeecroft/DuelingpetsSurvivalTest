module JukeboxesHelper

   private
      def getJukeboxParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "JukeboxId")
            value = params[:jukebox_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Jukebox")
            value = params.require(:jukebox).permit(:name, :description, :bookgroup_id, :privatejukebox,
            :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache, :gviewer_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def jukeboxValue(jukeboxFound)
         jukebox = Fieldcost.find_by_name("Jukebox")
         mainsheet = Fieldcost.find_by_name("Mainsheet")   
         subsheet = Fieldcost.find_by_name("Subsheet")
         sound = Fieldcost.find_by_name("Sound")
         allSheets = Subsheet.all
         subsheets = allSheets.select{|subsheet| subsheet.mainsheet.jukebox_id == jukeboxFound.id}
         allSounds = Sound.all
         sounds = allSounds.select{|sound| sound.reviewed && sound.subsheet.mainsheet.jukebox_id == jukeboxFound.id}
         points = (jukebox.amount + (jukeboxFound.mainsheets.count * mainsheet.amount) + (subsheets.count * subsheet.amount) + (sounds.count * sound.amount))
         return points
      end

      def getSoundCounts(mainsheet)
         #Need to revise
         allSounds = Sound.all
         sounds = allSounds.select{|sound| sound.reviewed && sound.subsheet.mainsheet_id == mainsheet.id}
         return sounds.count
      end

      def displayMusic(jukebox, type)
         sound = nil

         #Displays the audios when the index page is open
         if(type == "index" && jukebox.mainsheets.count > 0)
            mainsheet = jukebox.mainsheets.order("updated_on desc", "created_on desc").first
            subsheet = mainsheet.subsheets.order("updated_on desc", "created_on desc").first
            if(mainsheet.subsheets.count > 0)
               #raise "my songs are: #{subsheet.sounds.count}"
               sound = subsheet.sounds.order("updated_on desc", "created_on desc").first
               #raise "My song clip is: #{sound.song}"
            end
         end

         #Displays the audios when the show page is open
         if(type == "show" && jukebox.subsheets.count > 0)
            subsheet = jukebox.subsheets.order("updated_on desc", "created_on desc").first
            sound = subsheet.sounds.order("updated_on desc", "created_on desc").first
         end

         #Displays the audios when the subsheet is open
         if(type == "subsheet" && jukebox.sounds.count > 0)
            sound = jukebox.sounds.order("updated_on desc", "created_on desc").first
         end

         #Displays the audio when the song is open -- This needs to be deleted
         if(type == "sound")
            sound = jukebox
         end
         return sound
      end

      def getMainsheetMusic(mainsheet)
         #Need to revise
         allSubsheets = mainsheet.subsheets.order("updated_on desc", "created_on desc")
         value = nil
         if(allSubsheets.count > 0)
            subsheets = allSubsheets.select{|subsheet| !subsheet.privatesubsheet}
            value = getSubsheetMusic(subsheets.first)
         end
         return value
      end
      
      def activateIntroVideo
         #Staff, jukeboxOwner
         logged_in = current_user
         jukeboxFound = Jukebox.find_by_name(getJukeboxParams("Id"))
         staff = (logged_in && jukeboxFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         jukeboxOwner = (logged_in && jukeboxFound && logged_in.id == jukeboxFound.user_id)
         if(staff || jukeboxOwner)
            jukeboxFound.toggle(:music_on)
            @jukebox = jukeboxFound
            @jukebox.save
            if(staff)
               redirect_to jukeboxes_list_path
            else
               redirect_to user_jukeboxes_path(jukeboxFound.user)
            end
         else
            if(!jukeboxFound)
               flash[:error] = "The jukebox does not exist!"
            else
               flash[:error] = "User doesn't have permission to activate the music!"
            end
            redirect_to root_path
         end
      end

      def indexpage
         userFound = User.find_by_vname(getJukeboxParams("User"))
         if(userFound)
            userJukeboxes = userFound.jukeboxes.order("updated_on desc, created_on desc")
            jukeboxes = userJukeboxes
            @user = userFound
         else
            allJukeboxes = Jukebox.order("updated_on desc, created_on desc")
            jukeboxes = allJukeboxes
         end
         @jukeboxes = Kaminari.paginate_array(jukeboxes).page(getJukeboxParams("Page")).per(10)
      end
      
      def showpage
         #Staff, jukeboxOwner and guests
         logged_in = current_user
         jukeboxFound = Jukebox.find_by_name(getJukeboxParams("Id"))
         staff = (logged_in && jukeboxFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         jukeboxOwner = (logged_in && jukeboxFound && logged_in.id == jukeboxFound.user_id)
         guests = jukeboxFound
         if(staff || jukeboxOwner || guests)
            @jukebox = jukeboxFound
            if(guests)
               #Only show the mainsheets that the user can view
               mainsheets = jukeboxFound.mainsheets.order("updated_on desc", "created_on desc")#.select{|sheet| checkBookgroupStatus(sheet)}
               @mainsheets = Kaminari.paginate_array(mainsheets).page(getJukeboxParams("Page")).per(10)
               
               #Finds the subsheets that belong to the jukebox
               sheets = Subsheet.select{|sheet| sheet.mainsheet.jukebox_id == jukeboxFound.id} #.select{|sheet| checkBookgroupStatus(sheet.mainsheet) && sheet.mainsheet.jukebox_id == jukeboxFound.id}
               @subsheets = sheets.count
               
               #Finds the sounds that belong to the jukebox
               sounds = Sound.select{|sound| sound.reviewed && sound.subsheet.mainsheet.jukebox_id == jukeboxFound.id} #checkBookgroupStatus(sound) && checkBookgroupStatus(sound.subsheet.mainsheet) && sound.subsheet.mainsheet.jukebox_id == jukeboxFound.id}
               @sounds = sounds.count
            else
               #Displays all the available mainsheets for the owner and staff
               mainsheets = jukeboxFound.mainsheets.order("updated_on desc", "created_on desc")
               @mainsheets = Kaminari.paginate_array(mainsheets).page(getJukeboxParams("Page")).per(10)
               
               #Finds the subsheets that belong to the jukebox
               sheets = Subsheet.select{|sheet| sheet.mainsheet.jukebox_id == jukeboxFound.id}
               @subsheets = sheets.count
               
               #Finds the sounds that belong to the jukebox
               sounds = Sound.select{|sound| sound.subsheet.mainsheet.jukebox_id == jukeboxFound.id}
               @sounds = sounds.count
            end
         else
            flash[:error] = "The jukebox does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Jukebox owner
         logged_in = current_user
         jukeboxFound = Jukebox.find_by_name(getJukeboxParams("Id"))
         staff = (logged_in && jukeboxFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         jukeboxOwner = (logged_in && jukeboxFound && logged_in.id == jukeboxFound.user_id)
         if(staff || jukeboxOwner)
            jukeboxFound.updated_on = currentTime
            @jukebox = jukeboxFound
            @user = User.find_by_vname(jukeboxFound.user.vname)
            if(type == "update")
               if(@jukebox.update_attributes(getJukeboxParams("Jukebox")))
                  flash[:success] = "Jukebox #{@jukebox.name} was successfully updated!"
                  redirect_to user_jukebox_path(@jukebox.user, @jukebox)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (jukeboxOwner && jukeboxFound.user.startgame)
               if(staff || owner)
                  if(!staff)
                     points = (jukeboxValue(channelFound) * 0.30).round
                     jukeboxFound.user.pouch.amount += points
                     @pouch = jukeboxFound.user.pouch
                     @pouch.save
                     economyTransaction("Source", points, jukeboxFound.user.id, "Points")
                  end
                  @jukebox.destroy
                  flash[:success] = "Jukebox #{@jukebox.name} was successfully removed!"
                  if(staff)
                     redirect_to jukeboxes_list_path
                  else
                     redirect_to user_jukeboxes_path(jukeboxFound.user)
                  end
               else
                  flash[:error] = "Jukebox owner #{jukeboxFound.user.vname} has not activated their game yet!"
                  redirect_to root_path
               end
            end
         else
            if(!jukeboxFound)
               flash[:error] = "The jukebox does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this jukebox!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         userFound = User.find_by_vname(getJukeboxParams("User"))
         owner = (logged_in && userFound && logged_in.id == userFound.id) #&& userFound.gameinfo.startgame)
         price = Fieldcost.find_by_name("Jukebox")
         if(owner) #&& userFound.pouch.amount - price.amount >= 0) #swap with emeralds later
            newJukebox = logged_in.jukeboxes.new
            if(type == "create")
               newJukebox = logged_in.jukeboxes.new(getJukeboxParams("Jukebox"))
               newJukebox.created_on = currentTime
               newJukebox.updated_on = currentTime
            end
            @jukebox = newJukebox
            @user = userFound
            if(type == "create")
               if(@jukebox.save)
                  #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                  #userFound.pouch.amount -= price.amount
                  #@pouch = userFound.pouch
                  #@pouch.save
                  
                  #Send the funds to the central bank
                  #rate = Ratecost.find_by_name("Purchaserate")
                  #tax = (price.amount * rate.amount)
                  #hoard = Dragonhoard.find_by_id(1)
                  #hoard.profit += tax
                  #@hoard = hoard
                  #@hoard.save
                  
                  #Keeps track of the economy
                  #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                  #economyTransaction("Tax", tax, logged_in.id, "Points")
                  flash[:success] = "Jukebox #{@jukebox.name} was successfully created."
                  redirect_to user_jukebox_path(@user, @jukebox)
               else
                  render "new"
               end
            end
         else
            if(!userFound)
               flash[:error] = "The user does not exist!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can create jukeboxes!"
            elsif(!userFound.gameinfo.startgame)
               flash[:error] = "User #{userFound.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{userFound.vname} can't afford the jukebox price!"
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
                  render "/jukeboxes/maintenance"
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
                  allJukeboxes = Jukebox.order("updated_on desc, created_on desc")
                  @jukeboxes = allJukeboxes.page(getJukeboxParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
