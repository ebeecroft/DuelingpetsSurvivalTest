module RatecostsHelper

   private
      def getRatecostParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "RatecostId")
            value = params[:ratecost_id]
         elsif(type == "Dragonhoard")
            value = params[:dragonhoard_id]
         elsif(type == "Ratecost")
            value = params.require(:ratecost).permit(:name, :amount, :econtype)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def priceChange(type)
         logged_in = current_user
         ratecostFound = Ratecost.find_by_id(getRatecostParams("Id"))
         staff = (logged_in && ratecostFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && ratecostFound && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         dragonhoard = Dragonhoard.find_by_id(1)
         price = ((ratecostFound.amount + ratecostFound.baserate.amount) + dragonhoard.rateprice * 0.45).round
         
         #Updates the price for the ratecost
         if((staff || glitchy) && dragonhoard.treasury - price >= 0)
            msg = ""
            if(type == "decrease")
               if(ratecostFound.amount - ratecostFound.baserate.amount >= 0)
                  ratecostFound.amount -= ratecostFound.baserate.amount
               else
                  ratecostFound.amount = 0
               end
               msg = "Ratecost #{@ratecost.name} was decremented!"
            else
               msg = "Ratecost #{@ratecost.name} was incremented!"
               ratecostFound.amount += ratecostFound.baserate.amount
            end
            
            #Decrements the treasury when updating the price for the ratecost
            dragonhoard.treasury -= price
            @hoard = dragonhoard
            @hoard.save
            @ratecost = ratecostFound
            @ratecost.save
            
            #Updates the economy
            economyTransaction("Sink", price, ratecostFound, "Points")
            flash[:success] = msg
            
            if(staff)
               redirect_to ratecosts_path
            else
               redirect_to dragonhoards_path
            end
         else
            if(!ratecostFound)
               flash[:error] = "The ratecost does not exist!"
            elsif(!logged_in || (logged_in.pouch.privilege != "Glitchy" && logged_in.pouch.privilege == "Admin" && logged_in.pouch.privilege != "Keymaster"))
               flash[:error] = "The user doesn't have permission to access this page!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "The dragonhoard doesn't have enough currency to update the rate!"
            end
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         ratecostFound = Ratecost.find_by_id(getRatecostParams("Id"))
         staff = (logged_in && ratecostFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         if(staff)
            #Sets up the new increment that the ratecost will update by
            ratecostFound.updated_on = currentTime
            allBaserates = Baserate.order("created_on desc")
            @baserates = allBaserates
            @ratecost = ratecostFound
            
            if(type == "update")
               #Saves the changes of the ratecost
               if(@ratecost.update_attributes(getRatecostParams("Ratecost")))
                  flash[:success] = "Ratecost #{@ratecost.name} was successfully updated!"
                  redirect_to ratecosts_path
               else
                  render "edit"
               end
            end
         else
            if(!ratecostFound)
               flash[:error] = "The ratecost does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         #Builds a new rate value for user features
         if(staff)
            newRatecost = Ratecost.new
            if(type == "create")
               newRatecost = Ratecost.new(getRatecostParams("Ratecost"))
               newRatecost.created_on = currentTime
               newRatecost.updated_on = currentTime
            end
            
            #Sets up the increment at which the rate increments by 
            allBaserates = Baserate.order("created_on desc")
            @baserates = allBaserates
            @ratecost = newRatecost
            
            if(type == "create")
               if(@ratecost.save)
                  flash[:success] = "Ratecost #{@ratecost.name} was successfully created!"
                  redirect_to ratecosts_path
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
                  allRatecosts = Ratecost.order("updated_on desc, created_on desc")
                  @ratecosts = Kaminari.paginate_array(allRatecosts).page(getRatecostParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create")
               #Staff only
               createCommons(type)
            elsif(type == "edit" || type == "update")
               #Staff only
               editCommons(type)
            elsif(type == "increase" || type == "decrease")
               #Glitchy only
               priceChange(type)
            end
         end
      end
end
