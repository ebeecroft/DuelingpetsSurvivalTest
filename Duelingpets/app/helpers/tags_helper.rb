module TagsHelper

   private
      def getTagParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "TagId")
            value = params[:tag_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Tag")
            value = params.require(:tag).permit(:name, :bookgroup_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def indexpage
         userFound = User.find_by_vname(getTagParams("User"))
         
         if(userFound)
            #Displays the user's tags
            userTags = userFound.tags.order("updated_on desc, created_on desc")
            tags = userTags
            @user = userFound
         else
            #Displays all available tags
            allTags = Tag.order("updated_on desc, created_on desc")
            tags = allTags
         end
         
         #Displays the tags that appropriate to the specific user
         reviewedTags = tags.select{|tag| (current_user && tag.user_id == current_user.id) || (checkBookgroupStatus(tag))}
         @tags = Kaminari.paginate_array(reviewedTags).page(getTagParams("Page")).per(50)
      end

      def editCommons(type)
         #Staff and Tag owner
         logged_in = current_user
         tagFound = Tag.find_by_id(getTagParams("Id"))
         staff = (logged_in && tagFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         tagOwner = (logged_in && tagFound && logged_in.id == tagFound.user_id)
         
         if(staff || tagOwner)
            tagFound.updated_on = currentTime
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @tag = tagFound
            @user = User.find_by_vname(tagFound.user.vname)
            
            if(type == "update")
               if(@tag.update_attributes(getTagParams("Tag")))
                  flash[:success] = "Tag #{@tag.name} was successfully updated!"
                  redirect_to user_tags_path(@tag.user)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("Tagcleanup")
               owner = (tagOwner && tagFound.user.startgame && tagFound.user.pouch.amount - price.amount >= 0)

               if(staff || owner)
                  if(!staff)
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch.amount
                     @pouch.save
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @tag.destroy
                  flash[:success] = "Tag #{@tag.name} was successfully removed!"
                  if(staff)
                     redirect_to tags_list_path
                  else
                     redirect_to user_tags_path(tagFound.user)
                  end
               else
                  if(!logged_in.gameinfo.startgame)
                     flash[:error] = "Owner #{logged_in.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Owner #{logged_in.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!tagFound)
               flash[:error] = "The tag does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this tag!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         #Collects the user data needed to create a new tag
         logged_in = current_user
         price = Fieldcost.find_by_name("Tag")
         rate = Ratecost.find_by_name("Purchaserate")
         tax = (price.amount * rate.amount)
         owner = (logged_in && logged_in.gameinfo.startgame && logged_in.pouch.amount - price.amount >= 0)
         
         if(owner)
            newTag = logged_in.tags.new
            if(type == "create")
               #Builds a new tag for the user
               newTag = logged_in.tags.new(getTagParams("Tag"))
               newTag.created_on = currentTime
               newTag.updated_on = currentTime
            end
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @tag = newTag
            @user = logged_in
            
            if(type == "create")
               if(@tag.save)
                  #Decrements the user's pouch for each tag created
                  logged_in.pouch.amount -= price.amount
                  @pouch = logged_in.pouch
                  @pouch.save
                  hoard = Dragonhoard.find_by_id(1)
                  hoard.profit += tax
                  @hoard = hoard
                  @hoard.save
                  
                  #Builds a new transaction for the economy
                  economyTransaction("Sink", price.amount - tax, newTag.user.id, "Points")
                  economyTransaction("Tax", tax, newTag.user.id, "Points")
                  flash[:success] = "Tag #{@tag.name} was successfully created!"
                  redirect_to user_tags_path(@user)
               else
                  render "new"
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can create new tags!"
            elsif(!subplaylistFound.user.gameinfo.startgame)
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{logged_in.vname} can't afford the tag price!"
            end
            redirect_to root_path
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
               if(type == "index")
                  indexpage
               elsif(type == "new" || type == "create")
                  createCommons(type)
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            if(type == "index")
               indexpage
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
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "list")
               #Staff only
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Reviewer"))
               if(staff)
                  allTags = Tag.order("updated_on desc, created_on desc")
                  @tags = allTags.page(getTagParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
