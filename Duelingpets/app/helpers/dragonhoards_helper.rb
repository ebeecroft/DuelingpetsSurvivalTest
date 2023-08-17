module DragonhoardsHelper

   private
      def getHoardParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Hoard")
            value = params.require(:dragonhoard).permit(:name, :message, :dragonimage, :remote_dragonimage_url,
            :dragonimage_cache, :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache,
            :basecost, :baserate)
         elsif(type == "ShelfId")
            value = params[:witemshelf][:witemshelf_id]
         elsif(type == "ItemId")
            value = params[:witemshelf][:item_id]
         elsif(type == "DenId")
            value = params[:wpetden][:wpetden_id]
         elsif(type == "CreatureId")
            value = params[:wpetden][:creature_id]
         elsif(type == "Wareobject")
            value = params.require(:wareobject).permit(:price)
         elsif(type == "WarehouseId")
            value = params[:warehouse][:warehouse_id]
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def getPetmarketStats(creature, type)
         stats = ""
         if(type == "Physical")
            msg1 = content_tag(:p, "Physical Stats")
            msg2 = content_tag(:p, "Level: #{creature.level}")
            msg3 = content_tag(:p, "HP: #{creature.hp}")
            msg4 = content_tag(:p, "Atk: #{creature.atk} | Def: #{creature.def}")
            msg5 = content_tag(:p, "Agi: #{creature.agility} | Strength: #{creature.strength}")
            stats = (msg1 + msg2 + msg3 + msg4 + msg5)
         elsif(type == "Magical")
            msg1 = content_tag(:p, "Magical Stats")
            msg2 = content_tag(:p, "MP: #{creature.mp}")
            msg3 = content_tag(:p, "Matk: #{creature.matk} | Mdef: #{creature.mdef}")
            msg4 = content_tag(:p, "Magi: #{creature.magi} | Mstr: #{creature.mstr}")
            stats = (msg1 + msg2 + msg3 + msg4)
         elsif(type == "Stamina")
            msg1 = content_tag(:p, "Stamina Stats")
            msg2 = content_tag(:p, "Fun: #{creature.fun}")
            msg3 = content_tag(:p, "Hunger: #{creature.hunger}")
            msg4 = content_tag(:p, "Thirst: #{creature.thirst}")
            stats = (msg1 + msg2 + msg3 + msg4)
         end
         return stats
      end

      def getMarketStats(item, type)
         stats = ""
         if(type == "Food")
            msg1 = content_tag(:p, "HP: #{item.hp}")
            msg2 = content_tag(:p, "Hunger: #{item.hunger}")
            msg3 = content_tag(:p, "Fun: #{item.fun}")
            stats = (msg1 + msg2 + msg3)
         elsif(type == "Drink")
            msg1 = content_tag(:p, "HP: #{item.hp}")
            msg2 = content_tag(:p, "Thirst: #{item.thirst}")
            msg3 = content_tag(:p, "Fun: #{item.fun}")
            stats = (msg1 + msg2 + msg3)
         elsif(type == "Weapon")
            msg1 = content_tag(:p, "Atk: #{item.atk}")
            msg2 = content_tag(:p, "Def: #{item.def}")
            msg3 = content_tag(:p, "Agi: #{item.agility}")
            msg4 = content_tag(:p, "Str: #{item.strength}")
            stats = (msg1 + msg2 + msg3 + msg4)
         elsif(type == "Toy")
            msg1 = content_tag(:p, "Fun: #{item.fun}")
            msg2 = content_tag(:p, "Hunger: #{item.hunger}")
            msg3 = content_tag(:p, "Thirst: #{item.thirst}")
            stats = (msg1 + msg2 + msg3)
         end
         return stats
      end

      def getEmeraldPrice(type) #Unsure if this function is still needed!
         price = 0
         if(type == "Buy")
            emeraldcost = Fieldcost.find_by_name("Emeraldpoints")
            emeraldrate = Ratecost.find_by_name("Emeraldrate")
            price = (emeraldcost.amount * emeraldrate.amount).round
         elsif(type == "Create")
            hoard = Dragonhoard.find_by_id(1)
            price = (hoard.basecost * hoard.baserate).round
         else
            flash[:error] = "Invalid selection!"
            redirect_to root_path
         end
         return price
      end

      def wareTransfer(type)
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         warehouses = Warehouse.all
         
         #Performs the transfer of points and emeralds for the dragonhoard
         if((staff || glitchy) && warehouses.count > 0)
            @warehouses = warehouses
            if(type == "warepost")
               points = params[:warehouse][:amount]
               emeralds = params[:warehouse][:emeralds]
               warehouse = Warehouse.find_by_id(getHoardParams("WarehouseId"))
               validTransfer = (dragonhoard.treasury - points.to_i >= 0 && dragonhoard.emeralds - emeralds.to_i >= 0)
               
               if(warehouse && validTransfer)
                  #Updates the dragonhoard and warehouse to reflect the changing currency
                  dragonhoard.treasury -= points.to_i
                  dragonhoard.emeralds -= emeralds.to_i
                  warehouse.hoardpoint += points.to_i
                  warehouse.emeralds += emeralds.to_i
                  @warehouse = warehouse
                  @warehouse.save
                  @dragonhoard = dragonhoard
                  @dragonhoard.save
                  
                  #Need to add a transfer option for this feature
                  economyTransaction("Sink", points.to_i, logged_in.id, "Points")
                  economyTransaction("Sink", emeralds.to_i, logged_in.id, "Emeralds")
                  flash[:success] = "The warehouse received #{points.to_i} points and #{emeralds.to_i} emeralds!"
                  redirect_to dragonhoards_path
               else
                  if(!warehouse)
                     flash[:error] = "The warehouse does not exist!"
                  elsif(dragonhoard.treasury - points.to_i < 0)
                     flash[:error] = "The dragonhoard can't transfer points it doesn't have!"
                  else
                     flash[:error] = "The dragonhoard can't transfer emeralds it doesn't have!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(warehouses.count == 0)
               flash[:error] = "There are no warehouses available to transfer points and emeralds to!"
            elsif(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can transfer the dragonhoard's wealth!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end
      
      def purchase(type)
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         wareshelf = Wareshelf.find_by_id("WareId")
         if((staff || glitchy) && wareshelf)
            waretype = params[:wareobject][:type]
            validMatch = false
            objectarray = nil
            if(waretype == "Creature" && wareshelf.shelftype == "Pillow")
               validMatch = true
               objectarray = Creature.find_by_id(params[:wareobject][:wareobject_id])
            elsif(waretype == "Item" && wareshelf.shelftype == "Shelf")
               validMatch = true
            end
            
            if(validMatch && objectarray && (dragonhoard.treasury - objectarray.cost >= 0) && (dragonhoard.emeralds - objectarray.emeraldcost >= 0))
               wareobject = Wareobject.select{|wareobject| wareobject.wareshelf_id == wareshelf.id && wareobject.wareobject_id == objectarray.id}
               if(wareobject)
                  wareobject.quantity += 1
               else
                  wareobject = Wareobject.new(getHoardParams("Wareobject"))
                  wareobject.quantity = 1
                  wareobject.wareshelf_id = wareshelf_id
                  wareobject.wareobject_id = objectarray.id
                  wareobject.price = 0
               end
               
               #Decrements the dragonhoard resources
               dragonhoard.treasury -= objectarray.cost
               dragonhoard.emeralds -= objectarray.emeraldcost
               @wareobject = wareobject
               @wareobject.save
               @dragonhoard = dragonhoard
               @dragonhoard.save
               
               #Gives the owner some points and emeralds that they can spend from the sale of the item or pet
               points = (objectarray.cost * 0.40).round
               emeralds = (objectarray.emeraldcost * 0.05).round
               creator = Pouch.find_by_user_id(objectarray.user_id)
               creator.amount += points
               creator.emeralds += emeralds
               @user = creator
               @user.save
               
               #Updates the status of the economy
               economyTransaction("Sink", objectarray.cost, logged_in.id, "Points")
               economyTransaction("Sink", objectarray.emeraldcost, logged_in.id, "Emeralds")
               economyTransaction("Source", points, creator.user.id, "Points")
               economyTransaction("Source", emeralds, creator.user.id, "Emeralds")
               flash[:success] = "Creator #{objectarray.user.vname} earned #{points} points and #{emeralds} emeralds from the sale!"
               redirect_to warehouse_path(wareshelf.warehouse.name)
            else
               if(!validMatch)
                  flash[:error] = "There is a mismatch between the type of ware and the object being chosen!"
               elsif(!objectarray)
                  flash[:error] = "The chosen object does not exist!"
               else
                  flash[:error] = "The dragonhoard can't afford to buy this wareobject!"
               end
               redirect_to root_path
            end
         else
            if(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can use this feature!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "The wareshelf does not exist!"
            end
            redirect_to root_path
         end
      end

      def market
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         
         if(staff || glitchy)
            #Displays the various items and pets that are available for sale
            itemsForSale = Item.order("reviewed_on desc, created_on desc").select{|item| item.reviewed}
            creaturesForSale = Creature.order("reviewed_on desc, created_on desc").select{|creature| creature.reviewed}
            @wareshelves = Wareshelf.all
            @items = Kaminari.paginate_array(itemsForSale).page(getHoardParams("Page")).per(30)
            @creatures = Kaminari.paginate_array(creaturesForSale).page(getHoardParams("Page")).per(16)
         else
            if(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can access the market!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def sendCurrencyToTheDragon
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         
         if(glitchy && dragonhoard.contestpoints > 0)
            #Transfers the converted treasury funds to Glitchy the dragon
            logged_in.pouch.amount += dragonhoard.contestpoints
            economyTransaction("Source", dragonhoard.contestpoints, logged_in.id, "Points")
            contestPoints = dragonhoard.contestpoints
            dragonhoard.contestpoints = 0
            @pouch = logged_in.pouch
            @pouch.save
            @dragonhoard = dragonhoard
            @dragonhoard.save
            flash[:success] = "Glitchy received #{contestPoints} contest points!"
            redirect_to dragonhoards_path
         else
            if(dragonhoard.contestpoints == 0)
               flash[:error] = "There are no contest points available for Glitchy to receive!"
            elsif(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can use this feature!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def contestPoints
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         
         if((staff || glitchy) && dragonhoard.treasury - dragonhoard.basecost >= 0)
            #Converts points from the treasury into contest points
            contestpoints = Fieldcost.find_by_name("Contestinc")
            dragonhoard.contestpoints += contestpoints.amount
            dragonhoard.treasury -= dragonhoard.basecost
            @dragonhoard = dragonhoard
            @dragonhoard.save
            economyTransaction("Sink", dragonhoard.basecost, logged_in.id, "Points")
            economyTransaction("Source", contestpoints.amount, logged_in.id, "Points")
            flash[:success] = "{contestpoints.amount} contest points were created!"
            redirect_to dragonhoards_path
         else
            if(dragonhoard.treasury - dragonhoard.basecost < 0)
               flash[:error] = "The dragonhoard can't afford to create a new contest points!"
            elsif(!logged_in || logged.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can create contest points!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def withdrawCurrencies
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         pointsAvailable = (dragonhoard.profit > 0 || dragonhoard.warepoints > 0 || dragonhoard.helperpoints > 0)
         
         if((staff || glitchy) && pointsAvailable)
            #Stores the collected points in the treasury
            dragonhoard.treasury += dragonhoard.profit
            dragonhoard.treasury += dragonhoard.warepoints
            dragonhoard.treasury += dragonhoard.helperpoints
            points = dragonhoard.profit + dragonhoard.warepoints + dragonhoard.helperpoints
            economyTransaction("Source", points, logged_in.id, "Points")
            dragonhoard.profit = 0
            dragonhoard.warepoints = 0
            dragonhoard.helperpoints = 0
            @dragonhoard = dragonhoard
            @dragonhoard.save
            flash[:success] = "The dragonhoard collected {points} points!"
            redirect_to dragonhoards_path
         else
            if(!pointsAvailable)
               flash[:error] = "There are no points available to withdraw!"
            elsif(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can withdraw points!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
         end
      end

      def buildEmerald
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         #Consider adding dreyore to craft emeralds and possibly magic
         price = (dragonhoard.basecost * dragonhoard.baserate).round
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         if((staff || glitchy) && dragonhoard.treasury - price >= 0)
            dragonhoard.emeralds += 1
            dragonhoard.treasury -= price
            economyTransaction("Sink", price, logged_in.id, "Points")
            economyTransaction("Source", 1, logged_in.id, "Emeralds")
            @dragonhoard = dragonhoard
            @dragonhoard.save
         else
            if(dragonhoard.treasury - price < 0)
               flash[:error] = "The dragonhoard can't afford to create a new emerald!"
            elsif(!logged_in || logged.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can create an emerald!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def purchaseEmerald
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         emeraldcost = Fieldcost.find_by_name("Emeraldpoints")
         emeraldrate = Ratecost.find_by_name("Emeraldrate")
         price = (emeraldcost.amount * emeraldrate.amount).round
         buyer = ((logged_in && logged_in.pouch.amount - price >= 0) && logged_in.gameinfo.startgame)
         
         #Determines if there any emeralds available for the player to buy
         if(buyer && dragonhoard.emeralds > 0)
            logged_in.pouch.amount -= price
            logged_in.pouch.emeraldamount += 1
            dragonhoard.emeralds -= 1
            profit = (price * 0.80).round
            dragonhoard.profit += profit
            
            #Updates the changes to the economy
            economyTransaction("Sink", price, logged_in.id, "Points")
            economyTransaction("Source", 1, logged_in.id, "Emeralds")
            economyTransaction("Sink", 1, logged_in.id, "Emeralds")
            economyTransaction("Tax", profit, 8, "Emeralds")
            
            #Updated the dragonhoard and the user's pouch
            @pouch = logged_in.pouch
            @pouch.save
            @dragonhoard = dragonhoard
            @dragonhoard.save
            flash[:success] = "Buyer #{logged_in.vname} purchased an emerald from the hoard!"
            redirect_to dragonhoards_path
         else
            if(dragonhoard.emeralds == 0)
               flash[:error] = "The dragonhoard has no emeralds available that it can sell!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can purchase emeralds!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "Buyer {logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "Buyer #{logged_in.vname} can't afford the emerald purchase price!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         dragonhoard = Dragonhoard.find_by_id(1)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         if(staff || glitchy)
            dragonhoardFound.updated_on = currentTime
            @dragonhoard = dragonhoardFound
            if(type == "update")
               if(@dragonhoard.update_attributes(getHoardParams("Hoard")))
                  flash[:success] = "Dragon hoard #{@dragonhoard.name} was successfully updated."
                  redirect_to dragonhoards_path
               else
                  render "edit"
               end
            end
         else
            if(!logged_in || logged_in.pouch.privilege != "Glitchy")
               flash[:error] = "Only the dragon Glitchy can edit the dragonhoard!"
            else
               flash[:error] = "Dragon {logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def indexpage
         hoard = Dragonhoard.find_by_id(1)
         @dragonhoard = hoard
         fieldcosts = hoard.fieldcosts
         @fieldcosts = Kaminari.paginate_array(fieldcosts).page(getHoardParams("Page")).per(10)
         ratecosts = hoard.ratecosts
         @ratecosts = Kaminari.paginate_array(ratecosts).page(getHoardParams("Page")).per(10)
         dreyores = hoard.dreyores
         @dreyores = Kaminari.paginate_array(dreyores).page(getHoardParams("Page")).per(10)
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
               elsif(type == "buyemeralds")
                  purchaseEmerald
               elsif(type == "createemeralds")
                  buildEmerald
               elsif(type == "withdraw")
                  withdrawCurrencies
               elsif(type == "convertpoints")
                  contestPoints
               elsif(type == "market")
                  market
               elsif(type == "buypet" || type == "buyitem")
                  purchase(type)
               elsif(type == "waretransfer" || type == "warepost")
                  wareTransfer(type)
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
            elsif(type == "buyemeralds")
               purchaseEmerald
            elsif(type == "createemeralds")
               buildEmerald
            elsif(type == "withdraw")
               withdrawCurrencies
            elsif(type == "convertpoints")
               contestPoints
            elsif(type == "transfer")
               sendCurrencyToTheDragon
            elsif(type == "market")
               market
            elsif(type == "buypet" || type == "buyitem") #Eventually merge this to one item
               purchase(type)
            elsif(type == "waretransfer" || type == "warepost")
               wareTransfer(type)
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
            elsif(type == "edit" || type == "update" || type == "createemeralds")
               #Glitchy only
               callMaintenance(type)
            elsif(type == "withdraw" || type == "convertpoints" || type == "transfer" || type == "waretransfer" || type == "warepost")
               #Glitchy only
               callMaintenance(type)
            elsif(type == "buyemeralds")
               #Logged in only
               callMaintenance(type)
            elsif(type == "petmarket" || type == "itemmarket" || type == "buyitem" || type == "buypet")
               #Glitchy only
               callMaintenance(type)
            end
         end
      end
end
