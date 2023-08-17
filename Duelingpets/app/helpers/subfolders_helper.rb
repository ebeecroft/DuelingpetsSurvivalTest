module SubfoldersHelper

   private
      def getSubfolderParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Mainfolder")
            value = params[:mainfolder_id]
         elsif(type == "Subfolder")
            value = params.require(:subfolder).permit(:title, :description, :collab_mode, :fave_folder, :privatesubfolder)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateGallery(mainfolder)
         mainfolder.updated_on = currentTime
         @mainfolder = mainfolder
         @mainfolder.save
         gallery = Gallery.find_by_id(@mainfolder.gallery_id)
         gallery.updated_on = currentTime
         @gallery = gallery
         @gallery.save
      end

      def showpage
         #Staff, subfolderOwner and guests
         logged_in = current_user
         subfolderFound = Subfolder.find_by_id(getSubfolderParams("Id"))
         staff = (logged_in && subfolderFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subfolderOwner = (logged_in && subfolderFound && logged_in.id == subfolderFound.user_id)
         guests = subfolderFound #&& checkBookgroupStatus(subfolderFound)
         
         if(staff || subfolderOwner || guests)
            @subfolder = subfolderFound
            if(guests)
               #Finds the arts that belong to the subfolder
               arts = subfolderFound.arts.order("updated_on desc", "created_on desc")#select{|art| art.reviewed && checkBookgroupStatus(art)}
               @arts = Kaminari.paginate_array(arts).page(getSubfolderParams("Page")).per(30)
            else
               #Finds the arts that belong to the subfolder
               arts = subfolderFound.arts.order("updated_on desc", "created_on desc")
               @arts = Kaminari.paginate_array(arts).page(getSubfolderParams("Page")).per(30)
            end
         else
            if(!subfolderFound)
               flash[:error] = "The subfolder does not exist!"
            else
               flash[:error] = "The user does not have access to view this folder!"
            end
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Subfolder owner
         logged_in = current_user
         subfolderFound = Subfolder.find_by_id(getSubfolderParams("Id"))
         staff = (logged_in && subfolderFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         subfolderOwner = (logged_in && subfolderFound && logged_in.id == subfolderFound.user_id)
         
         if(staff || subfolderOwner)
            subfolderFound.updated_on = currentTime
            @subfolder = subfolderFound
            @mainfolder = Mainfolder.find_by_id(subfolderFound.mainfolder_id)
            if(type == "update")
               if(@subfolder.update_attributes(getSubfolderParams("Subfolder")))
                  flash[:success] = "Subfolder #{@subfolder.name} was successfully updated!"
                  updateGallery(@subfolder.mainfolder)
                  redirect_to mainfolder_subfolder_path(@subfolder.mainfolder, @subfolder)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (subfolderOwner && subfolderFound.user.startgame)
               price = Fieldcost.find_by_name("Subfoldercleanup")
               if(staff || owner && subfolderFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     subfolderFound.user.pouch.amount -= price.amount
                     @pouch = subfolderFound.user.pouch.amount
                     @pouch.save
                     updateGallery(subfolderFound.mainfolder)
                     economyTransaction("Sink", price.amount, subfolderFound.user.id, "Points")
                  end
                  @subfolder.destroy
                  flash[:success] = "Subfolder #{subfolderFound.name} was successfully removed!"
                  if(staff)
                     redirect_to subfolders_path
                  else
                     redirect_to gallery_mainfolder_path(subfolderFound.mainfolder.gallery, subfolderFound.mainfolder)
                  end
               else
                  if(!subfolderFound.user.startgame)
                     flash[:error] = "Subfolder owner #{subfolderFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Subfolder owner #{subfolderFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!subfolderFound)
               flash[:error] = "The subfolder does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this subfolder!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Collects the user data needed to create a new subfolder
         logged_in = current_user
         mainfolderFound = Mainfolder.find_by_id(getSubfolderParams("Mainfolder"))
         owner = (logged_in && mainfolderFound && logged_in.id == mainfolderFound.user_id) #&& mainfolderFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Subfolder")
         freeFolder = (logged_in.galleries.count == 1 && logged_in.mainfolders.count == 1 && mainfolderFound.subfolders.count == 0)
         
         if(owner) #&& freeFolder || logged_in.pouch.amount - price.amount >= 0) #swap with emeralds later
            newSubfolder = mainfolderFound.subfolders.new
            if(type == "create")
               #Builds a new subfolder for the user
               newSubfolder = mainfolderFound.subfolders.new(getSubfolderParams("Subfolder"))
               newSubfolder.created_on = currentTime
               newSubfolder.updated_on = currentTime
               newSubfolder.user_id = logged_in.id
            end

            @subfolder = newSubfolder
            @mainfolder = mainfolderFound
            
            if(type == "create")
               if(@subfolder.save)
                  if(!freeFolder)
                     #Deducts the charges from the player's purse
                     #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                     #logged_in.pouch.amount -= price.amount #Emeralds might be added later for this section
                     #@pouch = logged_in.pouch
                     #@pouch.save
                  
                     #Central bank collects taxes from the creation of a new subfolder
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save

                     #Creates transactions for the newly created subfolder
                     #economyTransaction("Sink", price.amount, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Subfolder #{@subfolder.name} was successfully created!"
                  updateGallery(@subfolder.mainfolder)
                  redirect_to mainfolder_subfolder_path(@mainfolder, @subfolder)
               else
                  render "new"
               end
            end
         else
            if(!mainfolderFound)
               flash[:error] = "The mainfolder does not exist!"
            elsif(!logged_in || logged_in.id != mainfolderFound.user_id)
               flash[:error] = "Only the mainfolder owner can create subfolders!"
            elsif(!mainfolderFound.user.gameinfo.startgame)
               flash[:error] = "Mainfolder owner #{mainfolderFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Mainfolder owner #{mainfolderFound.user.vname} can't afford the subfolder price!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         galleryMode = Maintenancemode.find_by_id(14)
         if(allMode.maintenance_on || galleryMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
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
                  render "/galleries/maintenance"
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
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
               
               if(staff)
                  allSubfolders = Subfolder.order("updated_on desc, created_on desc")
                  @subfolders = allSubfolders.page(getSubfolderParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
