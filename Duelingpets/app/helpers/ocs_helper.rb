module OcsHelper

   private
      def getOcParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "OcId")
            value = params[:oc_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "OC")
            value = params.require(:oc).permit(:name, :description, :thumbnail, :bookgroup_id, :gviewer_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def indexpage
         userFound = User.find_by_vname(getOcParams("User"))
         if(userFound)
            userOcs = userFound.ocs.order("updated_on desc", "created_on desc")
            ocsReviewed = userOCs#.select{|oc| (current_user && oc.user_id == current_user.id) || (oc.reviewed && checkBookgroupStatus(oc))}
            ocs = ocsReviewed
            @user = userFound
         else
            allOCs = Oc.order("updated_on desc", "created_on desc")
            ocsReviewed = allOCs#.select{|oc| (current_user && oc.user_id == current_user.id) || (oc.reviewed && checkBookgroupStatus(oc))}
            ocs = ocsReviewed
         end
         @ocs = Kaminari.paginate_array(ocs).page(getOcParams("Page")).per(30)
      end

      def showpage
         #Staff, OC owner and guests
         logged_in = current_user
         ocFound = Oc.find_by_id(getOcParams("Id"))
         staff = (logged_in && ocFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         ocOwner = (logged_in && ocFound && logged_in.id == ocFound.user_id)
         guests = ocFound #&& checkBookgroupStatus(ocFound.bookgroup_id)
         
         if(staff || ocOwner || guests)
            @oc = ocFound
         else
            if(!ocFound)
               flash[:error] = "The oc does not exist!"
            #else
               #flash[:error] = "This content is restricted to higher bookgroups!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and OC owner
         logged_in = current_user
         ocFound = Oc.find_by_id(getOcParams("Id"))
         staff = (logged_in && ocFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         ocOwner = (logged_in && ocFound && logged_in.id == ocFound.user_id)
         
         if(staff || ocOwner)
            ocFound.updated_on = currentTime
            ocFound.reviewed = false
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            @oc = ocFound
            @user = User.find_by_vname(ocFound.user.vname)
            if(type == "update")
               if(@oc.update_attributes(getOcParams("OC")))
                  flash[:success] = "OC #{@oc.name} was successfully updated!"
                  redirect_to user_oc_path(@oc.user, @oc)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("Occleanup")
               owner = (ocOwner && ocFound.user.startgame && ocFound.user.pouch.amount - price.amount >= 0)
               if(staff || owner)
                  if(!staff)
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch.amount
                     @pouch.save
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @oc.destroy
                  flash[:success] = "OC #{@oc.name} was successfully removed!"
                  if(staff)
                     redirect_to movies_path
                  else
                     redirect_to mainplaylist_subplaylist_path(movieFound.subplaylist.mainplaylist, movieFound.subplaylist)
                  end
               else
                  if(!ocFound.user.startgame)
                     flash[:error] = "OC owner #{ocFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "OC owner #{ocFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!ocFound)
               flash[:error] = "The oc does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this oc!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         #Creates an original character if the user is logged in
         logged_in = current_user
         if(logged_in)
            newOc = logged_in.ocs.new
            if(type == "create")
               #Builds a new oc for the user
               newOc = logged_in.ocs.new(getOcParams("OC"))
               newOc.created_on = currentTime
               newOc.updated_on = currentTime
            end
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            gviewers = Gviewer.order("created_on desc")
            @gviewers = gviewers
            @oc = newOc
            @user = logged_in
            
            if(type == "create")
               if(@oc.save)
                  #Sets up the tag for ocs
                  octag = Octag.new(params[:octag]) #Will be rebuilt
                  octag.oc_id = @oc.id
                  octag.tag1_id = 1
                  @octag = octag
                  @octag.save
                  
                  #Returns the user to the show view of the new movie
                  url = "http://www.duelingpets.net/ocs/review"
                  ContentMailer.content_review(@oc, "OC", url).deliver_now
                  flash[:success] = "OC #{@oc.name} was successfully created!"
                  redirect_to user_oc_path(@user, @oc)
               else
                  render "new"
               end
            end
         else
            flash[:error] = "Only logged in users can create OCs!"
            redirect_to root_path
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         ocMode = Maintenancemode.find_by_id(8)
         if(allMode.maintenance_on || ocMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
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
                  render "/ocs/maintenance"
               end
            end
         else
            if(type == "index")
               indexpage
            elsif(type == "show")
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
               staff = (current_user && current_user.pouch.privilege == "Admin" || current_user.pouch.privilegge == "Keymaster" || current_user.pouch.privilege == "Reviewer")
               if(staff && (type == "list" || type == "review"))
                  allOCs = Oc.order("reviewed_on desc, created_on desc")
                  if(type == "review")
                     ocs = allOCs.select{|oc| !oc.reviewed}
                  else
                     ocs = allOCs
                  end
                  @ocs = Kaminari.paginate_array(ocs).page(getOcParams("Page")).per(30)
               elsif(staff && type == "approve")
                  ocFound = Oc.find_by_id(getOcParams("OcId"))
                  if(ocFound) #&& (ocFound.points_earned || ocFound.user.gameinfo.startgame))
                     #Updates the review stats of the approved oc
                     ocFound.reviewed_on = currentTime
                     ocFound.reviewed = true
                     
                     points = 0
                     #if(!ocFound.points_earned) #Support giving oc owner some points later
                     #   #Adds the points to the user's pouch
                     #   ocpoints = Fieldcost.find_by_name("OC")
                     #   points = ocpoints.amount
                     #   pouch = Pouch.find_by_user_id(ocFound.user_id)
                     #   pouch.amount += points
                     #   @pouch = pouch
                     #   @pouch.save
                     #   ocFound.points_earned = true
                     #   economyTransaction("Source", points, ocFound.user.id, "Points")
                     #end
                     
                     #Lets the user know that their oc has been approved
                     @oc = ocFound
                     @oc.save
                     ContentMailer.content_approved(@oc, "OC", points).deliver_now
                     flash[:success] = "User #{@oc.user.vname}'s oc #{@oc.name} was approved!"
                     redirect_to ocs_review_path
                  else
                     if(!ocFound)
                        flash[:error] = "OC does not exist!"
                     #else
                     #   flash[:error] = "User {ocFound.user.vname} has not activated their game yet!"
                     end
                     redirect_to root_path
                  end
               elsif(staff && type == "deny")
                  ocFound = Oc.find_by_id(getOcParams("OcId"))
                  if(ocFound)
                     @oc = ocFound
                     ContentMailer.content_denied(@oc, "OC").deliver_now
                     flash[:success] = "User #{@oc.user.vname}'s oc #{@oc.name} was denied!"
                     redirect_to ocs_review_path
                  else
                     flash[:error] = "OC does not exist!"
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
