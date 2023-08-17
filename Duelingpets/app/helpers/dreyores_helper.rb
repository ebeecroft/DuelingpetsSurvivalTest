module DreyoresHelper

   private
      def getDreyoreParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Dreyore")
            value = params.require(:dreyore).permit(:name, :change, :cap, :baseinc)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def worldOres(type)
         #Keeps track of the amount of ores in the world
         pouches = Pouch.all
         ores = pouches.select{|pouch| pouch.dreyterriumamount > 0} #This command should be renamed
         if(type == "Newbie")
            ores = pouches.select{|pouch| pouch.dreyterriumamount > 0 && pouch.firstdreyterrium} #Same here
         elsif(type == "Monster")
            ores = pouches.select{|pouch| pouch.dreyterriumamount > 0 && !pouch.firstdreyterrium}
         end
         
         return ores.amount
      end

      def indexpage
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         if(staff || glitchy)
            allDreyores = Dreyore.order("updated_on desc, created_on desc")
            @dreyores = Kaminari.paginate_array(allDreyores).page(getDreyoreParams("Page")).per(10)
         else
            if(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can use this feature!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         logged_in = current_user
         dreyoreFound = Dreyore.find_by_id(getDreyoreParams("Id"))
         staff = (logged_in && dreyoreFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && dreyoreFound && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         if(staff || glitchy)
            dreyoreFound.updated_on = currentTime
            @dreyore = dreyoreFound
            if(type == "update")
               if(@dreyore.update_attributes(getDreyoreParams("Dreyore")))
                  flash[:success] = "Dreyore #{@dreyore.name} was successfully updated!"
                  redirect_to ratecosts_path
               else
                  render "edit"
               end
            end
         else
            if(!dreyoreFound)
               flash[:error] = "The dreyore does not exist!"
            elsif(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can edit the dragonhoard!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def buildOre
         #Dreyore is a material that is used for the creation of pets and items
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         dreyoreFound = Dreyore.find_by_id(getDreyoreParams("Id"))
         staff = (logged_in && dreyoreFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && dreyoreFound && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         
         #Price numbers need to be changed from hardcoded values
         price = ((dreyoreFound.cur * 0.35) + (8 * dreyoreFound.baseinc)).round
         validOre = (dreyoreFound.cur + dreyoreFound.baseinc <= dreyoreFound.cap) && (dragonhoard.treasury - price >= 0)
         
         #Determines if the dreyore is valid
         if((staff || glitchy) && validOre)
            if(dreyoreFound.extracted != 0)
               dreyoreFound.extracted = 0
            end
            
            #Stores the updated dreyore numbers
            niblinsEarned = Fieldcost.find_by_name("Dreyterriumbase").amount
            dreyoreFound.price = niblinsEarned
            dragonhoard.treasury -= price
            @dreyore = dreyoreFound
            @dreyore.save
            @dragonhoard = dragonhoard
            @dragonhoard.save
            
            #Updates the changes in the economy
            economyTransaction("Sink", price, dreyoreFound, "Points")
            flash[:success] = "Dreyore #{dreyoreFound.name} was successfully increased!"
            redirect_to dragonhoards_path
         else
            if(!dreyoreFound)
               flash[:error] = "The dreyore does not exist!"
            elsif(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can edit the dragonhoard!"
            elsif(dreyoreFound.cur + dreyoreFound.baseinc > dreyoreFound.cap)
               flash[:error] = "Dreyore #{dreyore.name} at the dragonhoard is completely full!"
            else
               flash[:error] = "The dragonhoard can't afford to create new dreyore!"
            end
            redirect_to root_path
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         dragonhoardMode = Maintenancemode.find_by_id(10) #Needs own maintenance area
         if(allMode.maintenance_on || dragonhoardMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
            if(staff)
               if(type == "index")
                  indexpage
               elsif(type == "addore")
                  buildOre
               else
                  editCommons(type)
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/dragonhoards/maintenance"
               end
            end
         else
            if(type == "index")
               indexpage
            elsif(type == "addore")
               buildOre
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
               #Glitchy only
               callMaintenance(type)
            elsif(type == "edit" || type == "update" || type == "addore")
               #Glitchy only
               callMaintenance(type)
            end
         end
      end
end
