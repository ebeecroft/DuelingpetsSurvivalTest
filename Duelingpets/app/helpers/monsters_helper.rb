module MonstersHelper

   private
      def getMonsterParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Monster")
            value = params.require(:monster).permit(:name, :description, :image)#, :hp, :atk, :def, :agility, 
            #:mp, :matk, :mdef, :magi, :exp, :nightmare, :shinycraze, :party, :mischief, :rarity, :image,
            #:monstertype_id, :element_id)
            #:remote_image_url, :image_cache, :ogg, :remote_ogg_url, :ogg_cache, :mp3,
            #:remote_mp3_url, :mp3_cache, :monstertype_id, :element_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def indexpage
         #Displays the monsters that have been reviewed to guests
         logged_in = current_user
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         allMonsters = Monster.order("reviewed_on desc", "created_on desc")
         monstersReviewed = allMonsters.select{|monster| monster.reviewed || staff || (logged_in && logged_in.id == monster.user_id)}
         userFound = User.find_by_vname(getMonsterParams("User"))
         
         #Displays the user's monsters if one is used
         if(userFound)
            monstersReviewed = allMonsters.select{|monster| userFound.id == monster.user_id && (monster.reviewed || staff || logged_in.id == userFound.id)}
         end
         @monsters = Kaminari.paginate_array(monstersReviewed).page(getMonsterParams("Page")).per(50)
      end

      def showpage
         #Guests are only allowed to view content that has been already approved
         logged_in = current_user
         monsterFound = Monster.find_by_name(getMonsterParams("Id"))
         staff = logged_in && monsterFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && monsterFound && logged_in.id == monsterFound.user_id
         guests = monsterFound #Only reviewed/approved monsters can be visited by guests
         
         if(staff || owner || guests)
            @monster = monsterFound
            @traittypes = Traittype.all
            traitmaps = Traitmap.select{|traitmap| traitmap.entity_id == monsterFound.id && traitmap.entitytype_id == 2}
            @traitmaps = traitmaps
         else
            flash[:error] = "The monster does not exist!"
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Only staff and the monster owner can edit or delete the monster
         logged_in = current_user
         monsterFound = Monster.find_by_name(getMonsterParams("Id"))
         staff = logged_in && monsterFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && monsterFound && (logged_in.id == monsterFound.user_id)
         
         allMonstertypes = Monstertype.order("created_on desc")
         @monstertypes = allMonstertypes
         
         if(staff || owner)
            monsterFound.updated_in = currentTime
            monsterFound.reviewed = false
            @monster = monsterFound
            
            if(type == "update")
               if(@monster.update_attributes(getMonsterParams("Monster")))
                  flash[:success] = "Monster #{@monster.name} was successfully updated!"
                  redirect_to user_monster_path(@monster.user, @monster)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               monsterOwner = owner
               
               if(staff || monsterOwner)
                  @monster.destroy
                  economyTransaction("Sink", price, monsterFound.user.id, "Points")
                  flash[:success] = "Monster #{monsterFound.name} was successfully removed!"
                  
                  if(staff)
                     redirect_to monsters_path
                  else
                     redirect_to user_monsters_path(monsterFound.user)
                  end
               end
            end
         else
            if(!monsterFound)
               flash[:error] = "The monster does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this monster!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         
         if(logged_in)
            #Builds a new monster for the player
            newMonster = logged_in.monsters.new
            if(type == "create")
               newMonster = logged_in.monsters.new(getMonsterParams("Monster"))
               newMonster.created_on = currentTime
               newMonster.updated_on = currentTime
            end
            
            #Determines the type of monster
            allMonstertypes = Monstertype.order("created_on desc")
            @monstertypes = allMonstertypes
            
            #Need to replace with elemental shield
            #allShields = Elementalchart.all
            #@elementalcharts = allShields
            
            #allElements = Element.order("created_on desc")
            #@elements = allElements
            
            @user = logged_in
            @monster = newMonster
            
            #Stores the newly created monster
            if(type == "create" && @monster.save)
               url = "http://www.duelingpets.net/monsters/review"
               ContentMailer.content_review(@monster, "Monster", url).deliver_now
               flash[:success] = "Monster #{@monster.name} was successfully created!"
               redirect_to user_monster_path(@user, @monster)
            elsif(type == "create")
               render "new"
            end
         else
            flash[:error] = "Only logged in users can create monsters!"
            redirect_to root_path
         end
      end

      def staffpages(type)
         if(type == "list" || type == "review")
            allMonsters = Monster.order("reviewed_on desc", "created_on desc")
            monstersToReview = allMonsters.select{|monster| !monster.reviewed}
            if(type == "list")
               monstersToReview = allMonsters
            end
            @monsters = Kaminari.paginate_array(monstersToReview).page(getMonsterParams("Page")).per(50)
            #.page vs Kaminari paginate array
         elsif(type == "deny")
            monsterFound = Monster.find_by_name(getMonsterParams("Id"))
            if(monsterFound)
               #Setup a status that can be set to denied or approved or review
               #Once denied shouldn't show up in review, but edit should be available
               @monster = monsterFound
               #Need save here
               ContentMailer.content_denied(@monster, "Monster").deliver_now
               flash[:success] = "Creator #{@monster.user.vname}'s monster #{@monster.name} was denied!"
               redirect_to monsters_review_path
            else
               flash[:error] = "The monster does not exist!"
               redirect_to root_path
            end
         else
            monsterFound = Monster.find_by_name(getMonsterParams("Id"))
            gameStarted = monsterFound && monsterFound.user.gameinfo.startgame
            #Should this be a small source or a sink?
            if(gameStarted)
               monsterFound.reviewed = true
               monsterFound.reviewed_on = currentTime
               @monster = monsterFound
               #ContentMailer.content_approved(@monster, "Creature", price).deliver_now
               flash[:success] = "Creator #{@monster.user.vname}'s monster #{@monster.name} was approved!"
               redirect_to monsters_review_path
            else
               if(!monsterFound)
                  flash[:error] = "The monster does not exist!"
               else
                  flash[:error] = "Creator {monsterFound.user.vname} has not activated their game yet!"
               end
               redirect_to monsters_review_path
            end
         end
      end

      def callMaintenance(type)
         #Setups the maintenance modes for the monster
         allMode = Maintenancemode.find_by_id(1)
         monsterMode = Maintenancemode.find_by_id(15)
         staff = current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Keymaster" || current_user.pouch.privilege == "Reviewer")
         maintenanceActive = (allMode.maintenance_on || monsterMode.maintenance_on)
         
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
               render "/monsters/maintenance"
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
            elsif(type == "cave")
               #Unsure if this is login or guests
               flash[:error] = "This page does not currently function!"
               redirect_to root_path
            end
         end
      end
end
