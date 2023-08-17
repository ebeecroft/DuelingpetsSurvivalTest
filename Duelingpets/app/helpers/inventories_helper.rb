module InventoriesHelper

   private
      def getInventoryParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "InventoryId")
            value = params[:inventory_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Inventory")
            value = params.require(:inventory).permit(:name, :mergeitems, :stackitems)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def showpage
         logged_in = current_user
         inventoryFound = Inventory.find_by_id(getInventoryParams("Id"))
         staff = (logged_in && inventoryFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         inventoryOwner = (logged_in && inventoryFound && logged_in.id == inventoryFound.user_id)
         
         #Displays the items that are in the inventory
         if(staff || inventoryOwner)
            itemActions = Itemaction.all
            @inventory = inventoryFound
            @itemactions = itemActions
            inventoryItems = inventoryFound.inventoryitems.all
            @inventoryitems = Kaminari.paginate_array(inventoryItems).page(getInventoryParams("Page")).per(60)
         else
            if(!inventoryFound)
               flash[:error] = "The inventory does not exist!"
            else
               flash[:error] = "Only the inventory owner can view the items stored here!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         logged_in = current_user
         inventoryFound = Inventory.find_by_id(getInventoryParams("Id"))
         staff = (logged_in && inventoryFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         owner = (logged_in && inventoryFound && logged_in.id == inventoryFound.user_id)
         
         #Determines if we are looking at the owner of the inventory
         if(staff || owner)
            @inventory = inventoryFound
            if(type == "update")
               if(@inventory.update_attributes(getInventoryParams("Inventory")))
                  flash[:success] = "Inventory #{@inventory.name} was successfully updated!"
                  redirect_to user_inventory_path(@inventory.user, @inventory)
               else
                  render "edit"
               end
            else
               price = Fieldcost.find_by_name("Inventorycleanup")
               inventoryOwner = (owner && inventoryFound.user.gameinfo.startgame && (logged_in.inventories.count == 0 || logged_in.pouch.amount - price.amount >= 0))
               
               #Deletes the user's inventory
               if(staff || inventoryOwner)
                  if(!staff && logged_in.inventories.count > 0)
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch
                     @pouch.save
                     economyTransaction("Sink", price.amount, inventoryFound.user_id, "Points")
                  end
                  
                  @inventory.destroy
                  flash[:success] = "Inventory #{inventoryFound.name} was successfully removed!"
                  
                  if(staff)
                     redirect_to inventories_path
                  else
                     redirect_to user_path(inventoryFound.user)
                  end
               else
                  if(!inventoryFound.user.gameinfo.startgame)
                     flash[:error] = "Inventory owner #{inventoryFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Inventory owner #{inventoryFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!inventoryFound)
               flash[:error] = "The inventory does not exist!"
            else
               flash[:error] = "Only the owner of the inventory can view this section!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         price = Fieldcost.find_by_name("Inventory")
         owner = (logged_in && logged_in.gameinfo.startgame && (logged_in.inventories.count == 0 || logged_in.pouch.amount - price.amount >= 0))
         
         #Creates a new inventory for the user that can store items
         if(owner)
            newInventory = logged_in.inventories.new
            if(type == "create")
               newInventory = logged_in.inventories.new(getInventoryParams("Inventory"))
               newInventory.itemcapacity = 90 #Do not hard code this
               newInventory.itemqtylimit = 50 #This is okay to be hard coded
            end
            
            @inventory = newInventory
            @user = logged_in
            
            if(type == "create")
               if(@inventory.save)
                  if(logged_in.inventories.count > 0)

                     #Decrements the user's pouch
                     logged_in.pouch.amount -= price.amount #Unsure if this should be Tax or sink
                     @pouch = logged_in.pouch
                     @pouch.save
                     #economyTransaction("Sink", bookworldFound.price - tax, newBook.user.id, "Points")
                     #economyTransaction("Tax", tax, newBook.user.id, "Points")
                  end
                  
                  flash[:success] = "Inventory #{@inventory.name} was successfully created!"
                  redirect_to user_inventory_path(@user, @inventory)
               else
                  render "new"
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can create inventories!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{logged_in.vname} can't afford the inventory create price!"
            end
            redirect_to root_path
         end
      end

      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(10)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
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
                  render "/users/maintenance"
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
               #Staff only
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               if(staff)
                  allInventories = Inventory.order("id desc")
                  @inventories = Kaminari.paginate_array(allInventories).page(getInventoryParams("Page")).per(10)
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
