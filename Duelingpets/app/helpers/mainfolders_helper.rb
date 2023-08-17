module MainfoldersHelper

   private
      def getMainfolderParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Gallery")
            value = params[:gallery_id]
         elsif(type == "Mainfolder")
            value = params.require(:mainfolder).permit(:title, :description)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def updateGallery(gallery)
         gallery.updated_on = currentTime
         @gallery = gallery
         @gallery.save
      end

      def getSubfolderArt(subfolder) #Is this still necessary?
         allArts = subfolder.arts.order("updated_on desc", "reviewed_on desc")
         arts = allArts.select{|art| (art.reviewed && checkBookgroupStatus(art)) || (current_user && current_user.id == art.user_id)}
         return arts.first
      end

      def showpage
         #Staff, mainfolderOwner and guests
         logged_in = current_user
         mainfolderFound = Mainfolder.find_by_id(getMainfolderParams("Id"))
         staff = (logged_in && mainfolderFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainfolderOwner = (logged_in && mainfolderFound && logged_in.id == mainfolderFound.user_id)
         guests = mainfolderFound #&& checkBookgroupStatus(mainfolderFound)
         if(staff || mainfolderOwner || guests)
            @mainfolder = mainfolderFound
            if(guests)
               #Only show the subfolders that the user can view? This might get revised later as it might not make sense.
               folders = Subfolder.select{|folder| folder.mainfolder_id == mainfolderFound.id}
               @subfolders = Kaminari.paginate_array(folders).page(getMainfolderParams("Page")).per(10)
               
               #Finds the arts that belong to the mainfolder
               arts = Art.select{|art| art.reviewed && checkBookgroupStatus(art) && art.subfolder.mainfolder_id == mainfolderFound.id}
               @arts = arts.count
            else
               #Displays all the available subfolders for the owner and staff
               folders = mainfolderFound.subfolders
               @subfolders = Kaminari.paginate_array(folders).page(getMainfolderParams("Page")).per(10)
               
               #Finds the arts that belong to the mainfolder
               arts = Art.select{|art| art.subfolder.mainfolder_id == mainfolderFound.id}
               @arts = arts.count
            end
         else
            if(!mainfolderFound)
               flash[:error] = "The mainfolder does not exist!"
            else
               flash[:error] = "The user does not have access to view this folder!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff, and Mainfolder owner
         logged_in = current_user
         mainfolderFound = Mainfolder.find_by_id(getMainfolderParams("Id"))
         staff = (logged_in && mainfolderFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         mainfolderOwner = (logged_in && mainfolderFound && logged_in.id == mainfolderFound.user_id)
         
         if(staff || mainfolderOwner)
            mainfolderFound.updated_on = currentTime
            @mainfolder = mainfolderFound
            @gallery = Gallery.find_by_name(mainfolderFound.gallery.name)
            if(type == "update")
               if(@mainfolder.update_attributes(getMainfolderParams("Mainfolder")))
                  flash[:success] = "Mainfolder #{@mainfolder.name} was successfully updated!"
                  updateGallery(@mainfolder.gallery)
                  redirect_to gallery_mainfolder_path(@mainfolder.gallery, @mainfolder)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (mainfolderOwner && mainfolderFound.user.startgame)
               price = Fieldcost.find_by_name("Mainfoldercleanup")
               if(staff || owner && mainfolderFound.user.pouch.amount - price.amount >= 0)
                  if(!staff)
                     mainfolderFound.user.pouch.amount -= price.amount
                     @pouch = mainfolderFound.user.pouch.amount
                     @pouch.save
                     updateGallery(mainfolderFound.gallery)
                     economyTransaction("Sink", price.amount, mainfolderFound.user.id, "Points")
                  end
                  @mainfolder.destroy
                  flash[:success] = "Mainfolder #{@mainfolder.name} was successfully removed!"
                  if(staff)
                     redirect_to mainfolders_path
                  else
                     redirect_to user_gallery_path(mainfolderFound.gallery.user, mainfolderFound.gallery)
                  end
               else
                  if(!mainfolderFound.user.startgame)
                     flash[:error] = "Mainfolder owner #{mainfolderFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Mainfolder owner #{mainfolderFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!mainfolderFound)
               flash[:error] = "The mainfolder does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this mainfolder!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         #Collects the user data needed to create a new mainfolder
         logged_in = current_user
         galleryFound = Gallery.find_by_name(getMainfolderParams("Gallery"))
         owner = (logged_in && galleryFound && logged_in.id == galleryFound.user_id) #&& galleryFound.user.gameinfo.startgame)
         price = Fieldcost.find_by_name("Mainfolder")
         freeFolder = (logged_in.galleries.count == 1 && galleryFound.mainfolders.count == 0)
         #raise "My status for the if check is: #{owner && freeFolder || (logged_in.pouch.amount - price.amount >= 0)}"
         #raise "My Freefolder Status: #{freeFolder}"
         
         if(owner) #&& freeFolder || (logged_in.pouch.amount - price.amount >= 0)) #swap with emeralds later
            newMainfolder = galleryFound.mainfolders.new
            if(type == "create")
               #Builds a new mainfolder for the user
               newMainfolder = galleryFound.mainfolders.new(getMainfolderParams("Mainfolder"))
               newMainfolder.created_on = currentTime
               newMainfolder.updated_on = currentTime
               newMainfolder.user_id = logged_in.id
            end
            
            @mainfolder = newMainfolder
            @gallery = galleryFound
            
            if(type == "create")
               if(@mainfolder.save)
                  if(!freeFolder)
                     #Deducts the charges from the player's purse
                     #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                     #logged_in.pouch.amount -= price.amount #Emeralds might be added later for this section
                     #@pouch = logged_in.pouch
                     #@pouch.save
                  
                     #Central bank collects taxes from the creation of a new mainfolder
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save

                     #Creates transactions for the newly created mainfolder
                     #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Mainfolder #{@mainfolder.name} was successfully created!"
                  updateGallery(@mainfolder.gallery)
                  redirect_to gallery_mainfolder_path(@gallery, @mainfolder)
               else
                  render "new"
               end
            end
         else
            if(!galleryFound)
               flash[:error] = "The gallery does not exist!"
            elsif(!logged_in || logged_in.id != galleryFound.user_id)
               flash[:error] = "Only the gallery owner can create mainfolders!"
            elsif(!galleryFound.user.gameinfo.startgame)
               flash[:error] = "Gallery owner #{galleryFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "Gallery owner #{galleryFound.user.vname} can't afford the mainfolder price!"
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
                  allMainfolders = Mainfolder.order("updated_on desc, created_on desc")
                  @mainfolders = allMainfolders.page(getMainfolderParams("Page")).per(10)
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
