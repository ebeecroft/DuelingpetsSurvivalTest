module PmrepliesHelper

   private
      def getPMreplyParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "PMreplyId")
            value = params[:pmreply_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "PMreply")
            value = params.require(:pmreply).permit(:message, :image, :remote_image_url, :image_cache, :ogg, :remote_ogg_url, :ogg_cache,
            :mp3, :remote_mp3_url, :mp3_cache, :ogv, :remote_ogv_url, :ogv_cache, :mp4, :remote_mp4_url, :mp4_cache)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def editCommons(type)
         #Staff, Pmbox owner and PM owner
         logged_in = current_user
         pmreplyFound = Pmreply.find_by_id(getPmreplyParams("Id"))
         staff = (logged_in && pmreplyFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
         pmreplyOwner = (logged_in && pmreplyFound && logged_in.id == pmreplyFound.user_id)
         
         if(staff || pmreplyOwner)
            pmreplyFound.updated_on = currentTime
            @pmreply = pmreplyFound
            @pm = Pm.find_by_id(pmreplyFound.pm.id)
            if(type == "update")
               if(@pmreply.update_attributes(getPmreplyParams("Pmreply")))
                  @pm.updated_on = currentTime
                  @pm.save
                  flash[:success] = "PMreply was successfully updated!"
                  redirect_to pmbox_pm_path(@pmreply.pm.pmbox, @pmreply.pm)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("PMreplycleanup")
               owner = (pmreplyOwner && pmreplyFound.user.startgame && pmreplyFound.user.pouch.amount - price.amount >= 0)
               if(staff || owner)
                  if(!staff)
                     pmreplyFound.user.pouch.amount -= price.amount
                     @pouch = pmreplyFound.user.pouch
                     @pouch.save
                     economyTransaction("Sink", price.amount, pmreplyFound.user.id, "Points")
                  end
                  @pmreply.destroy
                  flash[:success] = "PMreply was successfully removed!"
                  if(staff)
                     redirect_to pmreplies_path
                  else
                     redirect_to pmbox_pm_path(@pmreply.pm.pmbox, @pmreply.pm)
                  end
               else
                  if(!pmreplyFound.user.startgame)
                     flash[:error] = "PMreply owner #{pmreplyFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "PMreply owner #{pmreplyFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!pmreplyFound)
               flash[:error] = "The pmreply does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this pmreply!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new mainplaylist
         logged_in = current_user
         pmFound = Pm.find_by_id(getPmreplyParams("Pm"))
         price = Fieldcost.find_by_name("PMreplycost")
         rate = Ratecost.find_by_name("Purchaserate")
         tax = (price.amount * rate.amount)
         sender = (logged_in && pmFound && logged_in.id == pmFound.user_id && pmFound.user.gameinfo.startgame && logged_in.pouch.amount - price.amount >= 0)
         receiver = (logged_in && pmFound && logged_in.id == pmFound.pmbox.user_id && pmFound.pmbox.user.gameinfo.startgame && logged_in.pouch.amount - price.amount >= 0) #Need to check if the pm is closed later
         
         if(sender || receiver)
            newPmreply = pmFound.pmreplies.new
            if(type == "create")
               #Builds a new pmreply for the user
               newPmreply = pmFound.pmreplies.new(getPmreplyParams("Pmreply"))
               newPmreply.created_on = currentTime
               newPmreply.updated_on = currentTime
               newPmreply.user_id = logged_in.id
               
               #Notifies the respective user that there is a new message
               pmFound.update_on = currentTime
               if(sender)
                  pmFound.user2_unread = true
               else
                  pmFound.user1_unread = true
               end
            end

            @pmreply = newPmreply
            @pm = pmFound
            
            if(type == "create")
               if(@pmreply.save)
                  #Deduct the points from the two users points pouch
                  logged_in.pouch.amount -= price.amount
                  @pouch = logged_in.pouch
                  @pouch.save
                  @pm.save

                  #Create new Economy Transactions
                  hoard = Dragonhoard.find_by_id(1)
                  hoard.profit += tax
                  @hoard = hoard
                  @hoard.save
                  economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  economyTransaction("Tax", tax, logged_in.id, "Points")

                  #Redirect back to the inbox after sending the message
                  url = "http://www.duelingpets.net/pmboxes/{@pm.pmbox_id}/pms/{@pm.id}"
                  CommunityMailer.messaging(@pm, "PM", url).deliver_now
                  flash[:success] = "PMreply was successfully created!"
                  redirect_to pmbox_pm_path(@pmreply.pm.pmbox, @pmreply.pm)
               else
                  render "new"
               end
            end
         else
            if(!pmFound)
               flash[:error] = "The pm does not exist!"
            elsif(!logged_in || logged_in.id != pmFound.user_id && logged_in.id != pmFound.pmbox.user_id)
               flash[:error] = "Only the sender and receiver can send pmreplies!"
            elsif(!pmFound.user.gameinfo.startgame)
               flash[:error] = "Sender #{logged_in.vname} has not activated their game yet!"
            elsif(!pmFound.pmbox.user.gameinfo.startgame)
               flash[:error] = "Receiver #{logged_in.user.vname} has not activated their game yet!"
            elsif(logged_in.pouch.amount - sharedCost < 0)
               flash[:error] = "Sender #{logged_in.vname} can't afford the pmreply price!"
            else
               flash[:error] = "Receiver #{logged_in.user.vname} can't afford the pmreply price!"
            end
            redirect_to root_path
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Betawriter"))
            if(staff)
               if(type == "new" || type == "create")
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
            if(type == "new" || type == "create")
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
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))

               if(staff)
                  allPmreplies = Pmreply.order("created_on desc")
                  @pmreplies = Kaminari.paginate_array(allPmreplies).page(getPmreplyParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
