module PmsHelper

   private
      def getPmParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "PmId")
            value = params[:pm_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Pm")
            value = params.require(:pm).permit(:title, :message, :image, :remote_image_url, :image_cache, :ogg, :remote_ogg_url, :ogg_cache,
            :mp3, :remote_mp3_url, :mp3_cache, :ogv, :remote_ogv_url, :ogv_cache, :mp4, :remote_mp4_url, :mp4_cache)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def unreadPMs(pm)
         title = ""
         if(pm.user1_unread || pm.user2_unread)
            title = (pm.title + "[*]")
         else
           title = pm.title
         end
         return title
      end

      def showpage
         #Staff, Pmbox owner, and PM owner
         logged_in = current_user
         pmFound = Pm.find_by_id(getPmParams("Id"))
         staff = (logged_in && pmFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
         pmOwner = (logged_in && pmFound && logged_in.id == pmFound.user_id)
         boxOwner = (logged_in && pmFound && logged_in.id == pmFound.pmbox.user_id)
         
         if(staff || boxOwner || pmOwner)
            if(boxOwner)
               pmFound.user2_unread = false
            elsif(pmOwner)
               pmFound.user1_unread = false
            end
            @pm = pmFound
            @pm.save
            pmReplies = @pm.pmreplies.order("created_on desc")
            @pmreplies = Kaminari.paginate_array(pmReplies).page(getPmParams("Page")).per(40)
         else
            if(!pmFound)
               flash[:error] = "The pm does not exist!"
            else
               flash[:error] = "The user does not permission to view this section!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff, Pmbox owner and PM owner
         logged_in = current_user
         pmFound = Pm.find_by_id(getPmParams("Id"))
         staff = (logged_in && pmFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
         pmOwner = (logged_in && pmFound && logged_in.id == pmFound.user_id)
         pmboxOwner = (logged_in && pmFound && logged_in.id == pmFound.pmbox.user_id)
         
         if(staff || pmOwner || pmboxOwner)
            pmFound.updated_on = currentTime
            @pm = pmFound
            @pmbox = Pmbox.find_by_id(pmFound.pmbox.id)
            if(type == "update")
               if(@pm.update_attributes(getPmParams("Pm")))
                  flash[:success] = "PM #{@pm.name} was successfully updated!"
                  redirect_to pmbox_pm_path(@pm.pmbox, @pm)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("PMcleanup")
               sender = (pmOwner && pmFound.user.startgame && pmFound.user.pouch.amount - price.amount >= 0)
               receiver = (pmOwner && pmFound.pmbox.user.startgame && pmFound.pmbox.user.pouch.amount - price.amount >= 0)
               if(staff || sender || receiver)
                  if(!staff)
                     if(sender)
                        pmFound.user.pouch.amount -= price.amount
                        pouch = pmFound.user.pouch
                     else
                        pmFound.pmbox.user.pouch.amount -= price.amount
                        pouch = pmFound.pmbox.user.pouch
                     end
                     @pouch = pouch
                     @pouch.save
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @pm.destroy
                  flash[:success] = "PM #{pmFound.name} was successfully removed!"
                  if(staff)
                     redirect_to pms_path
                  else
                     redirect_to pmboxes_inbox_path
                  end
               else
                  if(!pmFound.user.startgame)
                     flash[:error] = "Sender #{pmFound.user.vname} has not activated their game yet!"
                  elsif(!pmFound.pmbox.user.startgame)
                     flash[:error] = "Receiver #{pmFound.pmbox.user.vname} has not activated their game yet!"
                  elsif(pmFound.user.pouch.amount - price.amount < 0)
                     flash[:error] = "Sender #{pmFound.user.vname} can't afford the removal price!"
                  else
                     flash[:error] = "Receiver #{pmFound.pmbox.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!pmFound)
               flash[:error] = "The pm does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this pm!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new mainplaylist
         logged_in = current_user
         boxFound = Pmbox.find_by_id(getPmParams("Pmbox"))
         price = Fieldcost.find_by_name("PMcost")
         rate = Ratecost.find_by_name("Purchaserate")
         tax = (price.amount * rate.amount)
         sharedCost = price.amount / 2
         
         #Only sends private messages where the sender and receiver are not the same user
         validPM = (logged_in && boxFound && boxFound.box_open && logged_in.id != boxFound.user.id && (logged_in.pouch.amount - sharedCost >= 0 && boxFound.user.pouch.amount - sharedCost >= 0) && logged_in.gameinfo.startgame && boxFound.user.gameinfo.startgame)
         if(validPM)
            newMessage = boxFound.pms.new
            if(type == "create")
               #Builds a new pm for the user
               newMessage = boxFound.pms.new(getPmParams("Pm"))
               newMessage.created_on = currentTime
               newMessage.updated_on = currentTime
               newMessage.user_id = logged_in.id
               newMessage.user2_unread = true
            end
            
            @pm = newPm
            @pmbox = boxFound
            
            if(type == "create")
               if(@pm.save)
                  #Deduct the points from the two users points pouch
                  logged_in.pouch.amount -= sharedCost
                  boxFound.user.pouch.amount -= sharedCost
                  sender = logged_in.pouch
                  receiver = boxFound.user.pouch
                  @pouch1 = sender
                  @pouch1.save
                  @pouch2 = receiver
                  @pouch2.save
                  
                  #Create new Economy Transactions
                  hoard = Dragonhoard.find_by_id(1)
                  hoard.profit += tax
                  @hoard = hoard
                  @hoard.save
                  economyTransaction("Sink", sharedCost, logged_in.id, "Points")
                  economyTransaction("Sink", sharedCost, boxFound.user.id, "Points")
                  economyTransaction("Tax", tax, logged_in.id, "Points")
                  
                  #Redirect back to the inbox after sending the message
                  url = "http://www.duelingpets.net/pmboxes/inbox"
                  CommunityMailer.messaging(@pm, "PM", url).deliver_now
                  flash[:success] = "PM #{@pm.name} was successfully created!"
                  redirect_to pmboxes_inbox_path
               else
                  render "new"
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can send pms!"
            elsif(!boxFound)
               flash[:error] = "The pmbox does not exist!"
            elsif(!boxFound.box_open)
               flash[:error] = "The receiver's message box is not open to pms at this time!"
            elsif(logged_in.id == boxFound.user.id)
               flash[:error] = "The sender and receiver can't be the same person!"
            elsif(logged_in.pouch.amount - sharedCost < 0)
               flash[:error] = "Sender #{logged_in.vname} can't afford the pm price!"
            elsif(boxFound.pouch.amount - sharedCost < 0)
               flash[:error] = "Receiver #{boxFound.user.vname} can't afford the pm price!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "Sender #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "Receiver #{boxFound.user.vname} has not activated their game yet!"
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
                  render "/users/maintenance"
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
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))

               if(staff)
                  allPms = Pm.order("created_on desc")
                  @pms = Kaminari.paginate_array(allPms).page(getPmParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Login only
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
