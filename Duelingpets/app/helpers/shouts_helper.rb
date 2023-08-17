module ShoutsHelper

   private
      def getShoutParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "ShoutId")
            value = params[:shout_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Shout")
            value = params.require(:shout).permit(:message, :shoutbox_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def reviewCommons(type)
         #Staff and login only
         logged_in = current_user
         staff = logged_in && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"
         
         if(staff || logged_in)
            if(type == "review")
               shouts = Shout.order("reviewed_on desc, created_on desc").select{|shout| !shout.reviewed}
               if(!staff)
                  shouts = logged_in.shoutbox.shouts.select{|shout| !shout.reviewed}
               end
               @shouts = Kaminari.paginate_array(shouts).page(getShoutParams("Page")).per(30)
            elsif(type == "approve")
               shoutFound = Shout.find_by_id(getShoutParams("ShoutId"))
               price = Fieldcost.find_by_name("Shout")
               rate = Ratecost.find_by_name("Purchaserate")
               tax = (price.amount * rate.amount)
               if(shoutFound && shoutFound.points_paid || shoutFound.user.gameinfo.startgame && shoutFound.user.pouch.amount - price.amount >= 0)
                  #Updates the review stats of the approved shout
                  shoutFound.reviewed_on = currentTime
                  shoutFound.reviewed = true
                  
                  if(!shoutFound.points_paid)
                     #Decrements the user's pouch
                     shoutFound.user.pouch.amount -= price.amount
                     @pouch = shoutFound.user.pouch
                     @pouch.save
                     
                     #Central bank collects the tax
                     hoard = Dragonhoard.find_by_id(1)
                     hoard.profit += tax
                     @hoard = hoard
                     @hoard.save
                     economyTransaction("Sink", price.amount, shoutFound.user.id, "Points")
                     economyTransaction("Tax", tax, shoutFound.user.id, "Points")
                  end
                  
                  @shout = shoutFound
                  @shout.save
                  
                  #Send out an email to the shout owner
                  url = "None"
                  CommunityMailer.shouts(@shout, "Approved", url).deliver_now
                  flash[:success] = "User #{@shout.user.vname}'s shout message #{@shout.message} was approved!"
                  redirect_to shouts_review_path
               else
                  if(!shoutFound)
                     flash[:error] = "The shout does not exist!"
                  elsif(!shoutFound.user.gameinfo.startgame)
                     flash[:error] = "Shout owner #{shoutFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Shout owner #{shoutFound.user.vname} can't afford the shout price!"
                  end
                  redirect_to root_path
               end
            elsif(type == "deny")
               shoutFound = Shout.find_by_id(getShoutParams("ShoutId"))
               if(shoutFound)
                  @shout = shoutFound
                  url = "None"
                  CommunityMailer.shouts(@shout, "Denied", url).deliver_now
                  flash[:success] = "Shout owner #{shoutFound.user.vname}'s shout message #{shoutFound.message} was denied!"
                  redirect_to shouts_review_path
               else
                  flash[:error] = "The shout does not exist!"
                  redirect_to root_path
               end
            end
         else
            flash[:error] = "Only logged in users can view this page!"
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff, Shoutbox owner and Shout owner
         logged_in = current_user
         shoutFound = Shout.find_by_id(getShoutParams("Id"))
         staff = (logged_in && shoutFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
         shoutOwner = (logged_in && shoutFound && logged_in.id == shoutFound.user_id)
         shoutboxOwner = (logged_in && shoutFound && logged_in.id == shoutFound.shoutbox.user_id)
         
         if(staff || shoutOwner || shoutboxOwner)
            shoutFound.updated_on = currentTime
            shoutFound.reviewed = false
            @shout = shoutFound
            @shoutbox = Shoutbox.find_by_id(shoutFound.shoutbox)
            if(type == "update")
               if(@shout.update_attributes(getShoutParams("Shout")))
                  flash[:success] = "Shout was successfully updated!"
                  redirect_to user_path(@shout.shoutbox.user)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("Shoutcleanup")
               sender = (shoutOwner && shoutFound.user.startgame && shoutFound.user.pouch.amount - price.amount >= 0)
               receiver = (shoutboxOwner && shoutFound.shoutbox.user.startgame && shoutFound.shoutbox.user.pouch.amount - price.amount >= 0)
               if(staff || sender || receiver)
                  if(!staff)
                     if(sender)
                        shoutFound.user.pouch.amount -= price.amount
                        pouch = shoutFound.user.pouch
                     else
                        shoutFound.shoutbox.user.pouch.amount -= price.amount
                        pouch = shoutFound.shoutbox.user.pouch
                     end
                     @pouch = pouch
                     @pouch.save
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @shout.destroy
                  flash[:success] = "Shout was successfully removed!"
                  if(staff)
                     redirect_to shouts_path
                  else
                     redirect_to user_path(shoutFound.shoutbox.user)
                  end
               else
                  if(!shoutFound.user.startgame)
                     flash[:error] = "Sender #{shoutFound.user.vname} has not activated their game yet!"
                  elsif(!shoutFound.shoutbox.user.startgame)
                     flash[:error] = "Receiver #{shoutFound.shoutbox.user.vname} has not activated their game yet!"
                  elsif(shoutFound.user.pouch.amount - price.amount < 0)
                     flash[:error] = "Sender #{shoutFound.user.vname} can't afford the removal price!"
                  else
                     flash[:error] = "Receiver #{shoutFound.shoutbox.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!shoutFound)
               flash[:error] = "The shout does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this shout!"
            end
            redirect_to root_path
         end
      end

      def createpage
         logged_in = current_user
         boxFound = Shoutbox.find_by_id(getShoutParams("Shoutbox")) #Will go away sometime 
         price = Fieldcost.find_by_name("Shoutcost")
         rate = Ratecost.find_by_name("Purchaserate")
         tax = (price.amount * rate.amount)
         validShout = (logged_in && boxFound && boxFound.box_open && logged_in.id != boxFound.user.id && logged_in.pouch.amount - price.amount >= 0 && logged_in.gameinfo.startgame)
         
         if(validShout)
            newShout = boxFound.shouts.new(getShoutParams("Shout"))
            newShout.created_on = currentTime
            newShout.updated_on = currentTime
            newShout.user_id = logged_in.id
            @shout = newShout
            
            if(@shout.save)
               #Deducts the points from the user's pouch
               logged_in.pouch.amount -= price.amount
               @pouch = logged_in.pouch
               @pouch.save
               
               #Create new Economy Transactions
               hoard = Dragonhoard.find_by_id(1)
               hoard.profit += tax
               @hoard = hoard
               @hoard.save
               economyTransaction("Sink", price.amount, logged_in.id, "Points")
               economyTransaction("Tax", tax, logged_in.id, "Points")
               
               #Redirect back to the user's page
               url = "http://www.duelingpets.net/shouts/review"
               CommunityMailer.shouts(@shout, "Review", url).deliver_now
               flash[:success] = "User #{@shout.user.vname} shout was successfully created!"
               redirect_to user_path(logged_in)
            else
               flash[:error] = "Unable to save the shout message to the shoutbox!"
               redirect_to root_path
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can send shouts!"
            elsif(!boxFound)
               flash[:error] = "The shoutbox does not exist!"
            elsif(!boxFound.box_open)
               flash[:error] = "The receiver's shoutbox is not open to shouts at this time!"
            elsif(logged_in.id == boxFound.user.id)
               flash[:error] = "The sender and receiver can't be the same person!"
            elsif(logged_in.pouch.amount - sharedCost < 0)
               flash[:error] = "User #{logged_in.vname} can't afford the shout price!"
            else
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
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
               if(type == "create")
                  createpage
               elsif(type == "edit" || type == "update" || type == "destroy")
                  editCommons(type)
               else
                  reviewCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            if(type == "create")
               createpage
            elsif(type == "edit" || type == "update" || type == "destroy")
               editCommons(type)
            else
               reviewCommons(type)
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
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
               
               if(staff)
                  allShouts = Shout.order("created_on desc")
                  @shouts = Kaminari.paginate_array(allShouts).page(getShoutParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "review" || type == "approve" || type == "deny")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
