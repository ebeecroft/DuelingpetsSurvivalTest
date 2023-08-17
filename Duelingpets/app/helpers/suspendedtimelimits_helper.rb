module SuspendedtimelimitsHelper

   private
      def getTimelimitParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Timelimit")
            value = params.require(:suspendedtimelimit).permit(:reason, :user_id, :timelimit, :pointfines, :emeraldfines)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def editCommons(type)
         logged_in = current_user
         timelimitFound = Suspendedtimelimit.find_by_id(getSuspendedtimelimitParams("Id"))
         staff = (logged_in && timelimitFound && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")

         if(staff)
            allUsers = User.order("joined_on desc")
            users = allUsers.select{|user| user.pouch.privilege != "Admin" && user.pouch.privilege != "Glitchy" && user.pouch.privilege != "Bot" && user.pouch.privilege != "Trial"}
            @users = users
            @suspendedtimelimit = timelimitFound
            if(type == "update")
               if(@suspendedtimelimit.update_attributes(getTimelimitParams("Timelimit")))
                  flash[:success] = "Timelimit was successfully updated!"
                  redirect_to suspendedtimelimits_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               #Unbans the player
               pouchFound = Pouch.find_by_user_id(@suspendedtimelimit.user_id)
               pouchFound.banned = false
               @pouch = pouchFound
               @pouch.save
               
               #Deletes the previous suspension
               @suspendedtimelimit.destroy
               flash[:success] = "Player #{pouchFound.vname} was unbanned!"
               redirect_to suspendedtimelimits_path
            end
         else
            if(!timelimitFound)
               flash[:error] = "The suspendedtimelimit does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this suspendedtimelimit!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         
         if(staff)
            newSuspendedtimelimit = Suspendedtimelimit.new
            if(type == "create")
               newTimelimit = Suspendedtimelimit.new(getTimelimitParams("Timelimit"))
               newTimelimit.created_on = currentTime
               newTimelimit.from_user_id = logged_in.id
            end
            
            #Finds all normal users
            allUsers = User.order("joined_on desc")
            users = allUsers.select{|user| user.pouch.privilege != "Admin" && user.pouch.privilege != "Glitchy" && user.pouch.privilege != "Bot" && user.pouch.privilege != "Trial"}
            @users = users
            @suspendedtimelimit = newTimelimit
            
            if(type == "create")
               if(@suspendedtimelimit.save)
                  pouchFound = Pouch.find_by_user_id(@suspendedtimelimit.user_id)
                  pouchFound.banned = true
                  
                  if(newTimelimit.fines > 0)
                     #Decrements the player's pouch
                     pouchFound.amount -= @suspendedtimelimit.fines
                     economyTransaction("Sink", newTimelimit.fines, newTimelimit.user.id, "Points")
                  end
                  
                  @pouch = pouchFound
                  @pouch.save
                  flash[:success] = "Suspension limit was set for #{newTimelimit.user.vname}!"
                  redirect_to suspendedtimelimits_path
               else
                  render "new"
               end
            end
         else
            flash[:error] = "This page is restricted to Staff only!"
            redirect_to root_path
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
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  allTimelimits = Suspendedtimelimit.order("created_on desc")
                  @suspendedtimelimits = Kaminari.paginate_array(allTimelimits).page(getTimelimitParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create")
               #Staff only
               createCommons(type)
            elsif(type == "edit" || type == "update" || type == "destroy")
               #Staff only
               editCommons(type)
            end
         end
      end
end
