module ItemsHelper

   private
      def getItemParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Item")
            value = params.require(:item).permit(:name, :description, :image) #:hp, :atk, :def, :agility, :strength,
            #:mp, :matk, :mdef, :magi, :mstr, :hunger, :thirst, :fun, :rarity, :starter, :emeraldcost, :image, :itemtype_id, :equipable, :durability) #:itemart, :remote_itemart_url,
            #:itemart_cache, :itemtype_id, :equipable, :durability)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def indexpage
         #Displays the items that have been reviewed to guests
         logged_in = current_user
         staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         allItems = Item.order("reviewed_on desc", "created_on desc")
         itemsReviewed = allItems.select{|item| item.reviewed || staff || (logged_in && logged_in.id == item.user_id)}
         userFound = User.find_by_vname(getItemParams("User"))
         
         #Displays the user's items if one is used
         if(userFound)
            itemsReviewed = allItems.select{|item| userFound.id == item.user_id && (item.reviewed || staff || logged_in.id == userFound.id)}
         end
         @items = Kaminari.paginate_array(itemsReviewed).page(getItemParams("Page")).per(50)
      end
      
      def showpage
         #Guests are only allowed to view content that has been already approved
         logged_in = current_user
         itemFound = Item.find_by_name(getItemParams("Id"))
         staff = logged_in && itemFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && itemFound && logged_in.id == itemFound.user_id
         guests = itemFound #Only reviewed/approved items can be visited by guests
         
         if(staff || owner || guests)
            @item = itemFound
            @traittypes = Traittype.all
            traitmaps = Traitmap.select{|traitmap| traitmap.entity_id == itemFound.id && traitmap.entitytype_id == 3}
            @traitmaps = traitmaps
         else
            flash[:error] = "The item does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Only staff and the item owner can edit or delete the item
         logged_in = current_user
         itemFound = Item.find_by_name(getItemParams("Id"))
         staff = logged_in && itemFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer")
         owner = logged_in && itemFound && (logged_in.id == itemFound.user_id)
         
         allItemtypes = Itemtype.order("created_on desc")
         @itemtypes = allItemtypes
         
         if(staff || owner)
            itemFound.updated_in = currentTime
            itemFound.reviewed = false
            @item = itemFound
            
            if(type == "update")
               if(@item.update_attributes(getItemParams("Item")))
                  flash[:success] = "Item #{@item.name} was successfully updated!"
                  redirect_to user_item_path(@item.user, @item)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               itemOwner = owner
               
               if(staff || itemOwner)
                  @item.destroy
                  economyTransaction("Sink", price, itemFound.user.id, "Points")
                  flash[:success] = "Item #{itemFound.name} was successfully removed!"
                  
                  if(staff)
                     redirect_to items_path
                  else
                     redirect_to user_items_path(itemFound.user)
                  end
               end
            end
         else
            if(!itemFound)
               flash[:error] = "The item does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this item!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         
         if(logged_in)
            #Builds a new item for the player
            newItem = logged_in.items.new
            if(type == "create")
               newItem = logged_in.items.new(getItemParams("Item"))
               newItem.created_on = currentTime
               newItem.updated_on = currentTime
            end
            
            #Determines the type of item
            allItemtypes = Itemtype.order("created_on desc")
            @itemtypes = allItemtypes
            
            #Need to replace with elemental shield
            #allShields = Elementalchart.all
            #@elementalcharts = allShields
            
            #allElements = Element.order("created_on desc")
            #@elements = allElements
            
            @user = logged_in
            @item = newItem
            
            #Stores the newly created item
            if(type == "create" && @item.save)
               url = "http://www.duelingpets.net/items/review"
               ContentMailer.content_review(@item, "Item", url).deliver_now
               flash[:success] = "Item #{@item.name} was successfully created!"
               redirect_to user_item_path(@user, @item)
            elsif(type == "create")
               render "new"
            end
         else
            flash[:error] = "Only logged in users can create items!"
            redirect_to root_path
         end
      end
      
      def staffpages(type)
         if(type == "list" || type == "review")
            allItems = Item.order("reviewed_on desc", "created_on desc")
            itemsToReview = allItems.select{|item| !item.reviewed}
            if(type == "list")
               itemsToReview = allItems
            end
            @items = Kaminari.paginate_array(itemsToReview).page(getItemParams("Page")).per(50)
            #.page vs Kaminari paginate array
         elsif(type == "deny")
            itemFound = Item.find_by_name(getMonsterParams("Id"))
            if(itemFound)
               #Setup a status that can be set to denied or approved or review
               #Once denied shouldn't show up in review, but edit should be available
               @item = itemFound
               #Need save here
               ContentMailer.content_denied(@item, "Item").deliver_now
               flash[:success] = "Creator #{@item.user.vname}'s item #{@item.name} was denied!"
               redirect_to items_review_path
            else
               flash[:error] = "The item does not exist!"
               redirect_to root_path
            end
         else
            itemFound = Item.find_by_name(getItemParams("Id"))
            gameStarted = itemFound && itemFound.user.gameinfo.startgame
            #Should this be a small source or a sink?
            if(gameStarted)
               itemFound.reviewed = true
               itemFound.reviewed_on = currentTime
               @item = itemFound
               #ContentMailer.content_approved(@item, "Item", price).deliver_now
               flash[:success] = "Creator #{@item.user.vname}'s item #{@item.name} was approved!"
               redirect_to items_review_path
            else
               if(!itemFound)
                  flash[:error] = "The item does not exist!"
               else
                  flash[:error] = "Creator {itemFound.user.vname} has not activated their game yet!"
               end
               redirect_to items_review_path
            end
         end
      end
      
      def callMaintenance(type)
         #Setups the maintenance modes for the item
         allMode = Maintenancemode.find_by_id(1)
         itemMode = Maintenancemode.find_by_id(9)
         staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Keymaster" || current_user.pouch.privilege == "Reviewer"))
         maintenanceActive = (allMode.maintenance_on || itemMode.maintenance_on)
         
         #Displays the features to the users if the maintenance is not active
         if(staff || !maintenanceActive)
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
               render "/items/maintenance"
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
               logged_in = current_user
               staff = logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster" || logged_in.pouch.privilege == "Reviewer")
               if(staff)
                  staffpages(type)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "junkdealer" || type == "yesitem" || type == "noitem" || type == "choose" || type == "choosepost")
               #Currently broken
               flash[:error] = "This page does not currently function!"
               redirect_to root_path
            end
         end
      end
end

n = current_user
               passedInValues = params[:format]
               if(logged_in && !passedInValues.nil?)
                  slotindex, invslot = params[:format].split("/")
                  if(slotindex.to_s != "" && !invslot.to_s != "")
                     slot = Inventoryslot.find_by_id(invslot)
                     if(slot.inventory.user_id == logged_in.id)
                        if(logged_in.gameinfo.startgame)
                           #Finds the item the player is trying to get rid of
                           itemnum = getItemName(slotindex, slot, "Item")
                           @slotindex = slotindex
                           @item = itemnum
                           @invslot = slot
                           @points = (@item.cost * 0.20).round
                        else
                           flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                           redirect_to edit_gameinfo_path(logged_in.gameinfo)
                        end
                     else
                        redirect_to root_path
                     end
                  else
                     redirect_to root_path
                  end
               else
                  raise "Illegal operation!"
               end
            elsif(type == "yesitem" || type == "noitem")
               logged_in = current_user
               slot = Inventoryslot.find_by_id(params[:inventoryslot_id])
               slotindex = params[:slotindex_id]
               if(logged_in && slotindex && slot)
                  if(slot.inventory.user_id == logged_in.id)
                     itemcost = getItemName(slotindex, slot, "Points")
                     if(type == "yesitem")
                        if(logged_in.gameinfo.startgame)
                           itemname = getItemName(slotindex, slot, "Name")
                           updateInventory(slotindex, slot, "Discard")
                           @inventoryslot = slot
                           @inventoryslot.save
                           logged_in.pouch.amount += (itemcost * 0.20).round
                           @pouch = logged_in.pouch
                           @pouch.save
                           flash[:success] = "Item #{itemname} was succesfully sold!"
                           redirect_to user_inventory_path(@inventoryslot.inventory.user, @inventoryslot.inventory)
                        else
                           flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                           redirect_to edit_gameinfo_path(logged_in.gameinfo)
                        end
                     else
                        if(logged_in.gameinfo.startgame)
                           price = ((itemcost * 0.20) * 4)
                           if(logged_in.pouch.amount - price >= 0)
                              logged_in.pouch.amount -= price
                              @pouch = logged_in.pouch
                              @pouch.save
                           end
                           flash[:success] = "No worries youngen, come back when your ready. As you leave the junk dealer you notice your pouch is slightly lighter than it was before."
                           redirect_to user_path(slot.inventory.user)
                        else
                           flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                           redirect_to edit_gameinfo_path(logged_in.gameinfo)
                        end
                     end
                  else
                     redirect_to root_path
                  end
               else
                  redirect_to root_path
               end
            elsif(type == "choose" || type == "choosepost")
               logged_in = current_user
               if(logged_in)
                  allItemtypes = Itemtype.order("created_on desc")
                  @itemtypes = allItemtypes
                  if(type == "choosepost")
                     itemtype = Itemtype.find_by_id(params[:item][:itemtype_id])
                     redirect_to new_user_item_path(logged_in, itemtype.id)
                  end
               else
                  redirect_to root_path
               end
            end
         end
      end
end
