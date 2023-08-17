module CreaturesHelper

   private
      def getCreatureParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Creature")
            value = params.require(:creature).permit(:name, :description, :image)#:hp, :atk, :def, :agility, :strength, :mp, :matk, :mdef, :magi, :mstr, :hunger, :thirst, :fun, :lives, :rarity, :starter, :emeraldcost, :unlimitedlives, :image, :creaturetype_id, :element_id)
            #value = params.require(:creature).permit(:name, :description, :hp, :atk, :def, :agility, :strength, :mp, :matk, :mdef, :magi, :mstr, :hunger, :thirst, :fun, :lives, :rarity, :starter, :emeraldcost, :unlimitedlives, :image, :remote_image_url, :image_cache, :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache, :voiceogg, :remote_voiceogg_url, :voiceogg_cache, :voicemp3, :remote_voicemp3_url, :voicemp3_cache, :creaturetype_id, :element_id, :activepet, :remote_activepet_url, :activepet_cache)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def indexpage
         #Displays the creatures that have been reviewed to guests
         logged_in = current_user
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         allCreatures = Creature.order("reviewed_on desc", "created_on desc")
         creaturesReviewed = allCreatures.select{|creature| creature.reviewed || staff || (logged_in && logged_in.id == creature.user_id)}
         userFound = User.find_by_vname(getCreatureParams("User"))
         
         #Displays the user's creatures if one is used
         if(userFound)
            creaturesReviewed = allCreatures.select{|creature| userFound.id == creature.user_id && (creature.reviewed || staff || logged_in.id == userFound.id)}
         end
         @creatures = Kaminari.paginate_array(creaturesReviewed).page(getCreatureParams("Page")).per(50)
      end
      
      def showpage
         #Guests are only allowed to view content that has been already approved
         logged_in = current_user
         creatureFound = Creature.find_by_name(getCreatureParams("Id"))
         staff = logged_in && creatureFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && creatureFound && logged_in.id == creatureFound.user_id
         guests = creatureFound #Only reviewed/approved creatures can be visited by guests
         
         if(staff || owner || guests)
            @creature = creatureFound
            @traittypes = Traittype.all
            traitmaps = Traitmap.select{|traitmap| traitmap.entity_id == creatureFound.id && traitmap.entitytype_id == 1}
            @traitmaps = traitmaps 
         else
            flash[:error] = "The creature does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Only staff and the creature owner can edit or delete the creature
         logged_in = current_user
         creatureFound = Creature.find_by_name(getCreatureParams("Id"))
         staff = logged_in && creatureFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && creatureFound && (logged_in.id == creatureFound.user_id)
         
         allCreaturetypes = Creaturetype.order("created_on desc")
         @creaturetypes = allCreaturetypes
         
         if(staff || owner)
            creatureFound.updated_in = currentTime
            creatureFound.reviewed = false
            @creature = creatureFound
            
            if(type == "update")
               if(@creature.update_attributes(getCreatureParams("Creature")))
                  flash[:success] = "Creature #{@creature.name} was successfully updated!"
                  redirect_to user_creature_path(@creature.user, @creature)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               creatureOwner = owner
               
               if(staff || creatureOwner)
                  @creature.destroy
                  economyTransaction("Sink", price, creatureFound.user.id, "Points")
                  flash[:success] = "Creature #{creatureFound.name} was successfully removed!"
                  
                  if(staff)
                     redirect_to creatures_path
                  else
                     redirect_to user_creatures_path(creatureFound.user)
                  end
               end
            end
         else
            if(!creatureFound)
               flash[:error] = "The creature does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this creature!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         
         if(logged_in)
            #Builds a new creature for the player
            newCreature = logged_in.creatures.new
            if(type == "create")
               newCreature = logged_in.creatures.new(getCreatureParams("Creature"))
               newCreature.created_on = currentTime
               newCreature.updated_on = currentTime
            end
            
            #Determines the type of creature
            allCreaturetypes = Creaturetype.order("created_on desc")
            @creaturetypes = allCreaturetypes
            
            #Need to replace with elemental shield
            #allShields = Elementalchart.all
            #@elementalcharts = allShields
            
            #allElements = Element.order("created_on desc")
            #@elements = allElements
            
            @user = logged_in
            @creature = newCreature
            
            #Stores the newly created creature
            if(type == "create" && @creature.save)
               url = "http://www.duelingpets.net/creatures/review"
               ContentMailer.content_review(@creature, "Creature", url).deliver_now
               flash[:success] = "#{@creature.name} was successfully created."
               redirect_to user_creature_path(@user, @creature)
            elsif(type == "create")
               render "new"
            end
         else
            flash[:error] = "Only logged in users can create creatures!"
            redirect_to root_path
         end
      end
      
      def staffpages(type)
         if(type == "list" || type == "review")
            allCreatures = Creature.order("reviewed_on desc", "created_on desc")
            creaturesToReview = allCreatures.select{|creature| !creature.reviewed}
            if(type == "list")
               creaturesToReview = allCreatures
            end
            @creatures = Kaminari.paginate_array(creaturesToReview).page(getCreatureParams("Page")).per(50)
            #.page vs Kaminari paginate array
         elsif(type == "deny")
            creatureFound = Creature.find_by_name(getCreatureParams("Id"))
            if(creatureFound)
               #Setup a status that can be set to denied or approved or review
               #Once denied shouldn't show up in review, but edit should be available
               @creature = creatureFound
               #Need save here
               ContentMailer.content_denied(@creature, "Creature").deliver_now
               flash[:success] = "Creator #{@creature.user.vname}'s creature #{@creature.name} was denied!"
               redirect_to creatures_review_path
            else
               flash[:error] = "The creature does not exist!"
               redirect_to root_path
            end
         else
            creatureFound = Creature.find_by_name(getCreatureParams("Id"))
            gameStarted = creatureFound && creatureFound.user.gameinfo.startgame
            #Should this be a small source or a sink?
            if(gameStarted)
               creatureFound.reviewed = true
               creatureFound.reviewed_on = currentTime
               @creature = creatureFound
               #ContentMailer.content_approved(@creature, "Creature", price).deliver_now
               flash[:success] = "Creator #{@creature.user.vname}'s creature #{@creature.name} was approved!"
               redirect_to creatures_review_path
            else
               if(!creatureFound)
                  flash[:error] = "The creature does not exist!"
               else
                  flash[:error] = "Creator {creatureFound.user.vname} has not activated their game yet!"
               end
               redirect_to creatures_review_path
            end
         end
      end

      def callMaintenance(type)
         #Setups the maintenance modes for the creature
         allMode = Maintenancemode.find_by_id(1)
         creatureMode = Maintenancemode.find_by_id(10)
         staff = current_user && current_user.pouch.privilege == "Admin"
         #staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster" || current_user.pouch.privilege == "Reviewer"))
         maintenanceActive = (allMode.maintenance_on || creatureMode.maintenance_on)
         
         #Displays the features to the users if the maintenance is not active
         if(staff || !maintenanceActive)
            if(type == "index")
               indexpage
            elsif(type == "show")
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
               render "/creatures/maintenance"
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
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "list" || type == "review" || type == "approve" || type == "deny")
               #Staff only
               logged_in = current_user
               staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
               if(staff)
                  staffpages(type)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
