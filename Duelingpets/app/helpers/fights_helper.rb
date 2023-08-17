module FightsHelper

   private
      def getFightParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def showpage
         fightFound = Fight.find_by_id(getFightParams("Id"))
         staff = (logged_in && fightFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         petOwner = (logged_in && fightFound && logged_in.id == fightFound.user_id)
         
         #Displays the current battles that the pet has fought in
         if(staff || petOwner || fightFound)
            @fight = fightFound
            monbattles = fightFound.monsterbattles.all #Add more for battling pets and ones for boss like creatures
            @monsterbattles = Kaminari.paginate_array(monbattles).page(getFightParams("Page")).per(50)
         else
            #Currently Noop since nothing fails here
            flash[:error] = "The fight does not exist!"
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
                  allFights = Fight.order("id desc")
                  @fights = Kaminari.paginate_array(allFights).page(getFightParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Guests?
               showpage
            end
         end
      end
end
