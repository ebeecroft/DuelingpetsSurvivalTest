module GalleriesHelper

   private
      def getGalleryParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "GalleryId")
            value = params[:gallery_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Gallery")
            value = params.require(:gallery).permit(:name, :description, :bookgroup_id, :privategallery,
            :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache, :gviewer_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def galleryValue(galleryFound)
         #Will need revisions later for emeralds
         #Gallery cost variables
         gallery = Fieldcost.find_by_name("Gallery")
         mainfolder = Fieldcost.find_by_name("Mainfolder")   
         subfolder = Fieldcost.find_by_name("Subfolder")
         art = Fieldcost.find_by_name("Art")
         
         #Content that exists in a specific gallery
         allFolders = Subfolder.all
         subfolders = allFolders.select{|subfolder| subfolder.mainfolder.gallery_id == galleryFound.id}
         allArts = Art.all
         arts = allArts.select{|art| art.reviewed && art.subfolder.mainfolder.gallery_id == galleryFound.id}
         
         #Gallery's current price
         points = (gallery.amount + (galleryFound.mainfolders.count * mainfolder.amount) + (subfolders.count * subfolder.amount) + (arts.count * art.amount))
         return points
      end

      def displayImage(gallery, type)
         artwork = nil

         #Displays the images when the index page is open
         if(type == "index" && gallery.mainfolders.count > 0)
            mainfolder = gallery.mainfolders.order("updated_on desc", "created_on desc").first
            subfolder = mainfolder.subfolders.order("updated_on desc", "created_on desc").first
            if(mainfolder.subfolders.count > 0)
               #raise "my songs are: #{subsheet.sounds.count}"
               artwork = subfolder.arts.order("updated_on desc", "created_on desc").first
               #raise "My song clip is: #{sound.song}"
            end
         end

         #Displays the images when the show page is open
         if(type == "show" && gallery.subfolders.count > 0)
            subfolder = gallery.subfolders.order("updated_on desc", "created_on desc").first
            artwork = subfolder.arts.order("updated_on desc", "created_on desc").first
         end

         #Displays the images when the subfolder is open
         if(type == "subfolder" && gallery.arts.count > 0)
            artwork = gallery.arts.order("updated_on desc", "created_on desc").first
         end

         #Displays the image when the art is open -- This needs to be deleted
         if(type == "art")
            artwork = gallery
         end
         return artwork
      end

      #Redo this one later
      def getArtCounts(mainfolder)
         allArts = Art.all
         arts = allArts.select{|art| art.review && art.subfolder.mainfolder_id == mainfolder.id}
         return arts.count
      end

      #Redo this one later
      def getMainfolderArt(mainfolder)
         allSubfolders = mainfolder.subfolders.order("updated_on desc", "created_on desc")
         value = nil
         if(allSubfolders.count > 0)
            subfolders = allSubfolders.select{|subfolder| !subfolder.privatesubfolder}
            value = getSubfolderArt(subfolders.first)
         end
         return value
      end
      
      def activateIntroVideo
         #Staff, channelOwner
         logged_in = current_user
         galleryFound = Gallery.find_by_name(getGalleryParams("Id"))
         staff = (logged_in && galleryFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         galleryOwner = (logged_in && galleryFound && logged_in.id == galleryFound.user_id)
         
         #Activates or deactives the intro video
         if(staff || galleryOwner)
            galleryFound.toggle(:music_on)
            @gallery = galleryFound
            @gallery.save
            if(staff)
               redirect_to galleries_list_path
            else
               redirect_to user_galleries_path(galleryFound.user)
            end
         else
            if(!galleryFound)
               flash[:error] = "The gallery does not exist!"
            else
               flash[:error] = "User doesn't have permission to activate the music!"
            end
            redirect_to root_path
         end
      end

      def indexpage
         userFound = User.find_by_vname(getGalleryParams("User"))
         
         if(userFound)
            #Displays the user's galleries
            userGalleries = userFound.galleries.order("updated_on desc, created_on desc")
            galleries = userGalleries
            @user = userFound
         else
            #Displays all available galleries
            allGalleries = Gallery.order("updated_on desc, created_on desc")
            galleries = allGalleries
         end
         
         @galleries = Kaminari.paginate_array(galleries).page(getGalleryParams("Page")).per(50)
      end

      def showpage
         #Staff, Gallery owner, Guests
         logged_in = current_user
         galleryFound = Gallery.find_by_name(getGalleryParams("Id"))
         staff = (logged_in && galleryFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         galleryOwner = (logged_in && galleryFound && logged_in.id == galleryFound.user_id)
         guests = galleryFound
         
         #Displays the most current artwork inside the gallery
         if(staff || galleryOwner || guests)
            @gallery = galleryFound
            if(guests)
               #Only show the mainfolders that the user can view
               mainfolders = galleryFound.mainfolders.order("updated_on desc", "created_on desc") #.select{|folder| checkBookgroupStatus(folder)}
               @mainfolders = Kaminari.paginate_array(mainfolders).page(getGalleryParams("Page")).per(40) #Figure this out later
               
               #Finds the subfolders that belong to the gallery
               folders = Subfolder.select{|folder| folder.mainfolder.gallery_id == galleryFound.id} #checkBookgroupStatus(folder.mainfolder) && folder.mainfolder.gallery_id == galleryFound.id}
               @subfolders = folders.count #Might be wrong
               
               #Finds the arts that belong to the gallery
               arts = Art.select{|art| art.reviewed && checkBookgroupStatus(art) && checkBookgroupStatus(art.subfolder.mainfolder) && art.subfolder.mainfolder.gallery_id == galleryFound.id}
               @arts = arts.count
            else
               #Displays all the available folders for the owner and staff
               mainfolders = galleryFound.mainfolders.order("updated_on desc", "created_on desc")
               @mainfolders = Kaminari.paginate_array(mainfolders).page(getGalleryParams("Page")).per(40)
               
               #Finds the subfolders that belong to the gallery
               folders = Subfolder.select{|folder| folder.mainfolder.gallery_id == galleryFound.id}
               @subfolders = folders.count
               
               #Finds the arts that belong to the gallery
               arts = Art.select{|art| art.subfolder.mainfolder.gallery_id == galleryFound.id}
               @arts = arts.count
            end
         else
            flash[:error] = "The gallery does not exist!"
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff and Gallery owner
         logged_in = current_user
         galleryFound = Gallery.find_by_name(getGalleryParams("Id"))
         staff = (logged_in && galleryFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         owner = (logged_in && galleryFound && logged_in.id == galleryFound.user_id)
         
         if(staff || owner)
            galleryFound.updated_in = currentTime
            @gallery = galleryFound
            
            if(type == "update")
               if(@gallery.update_attributes(getGalleryParams("Gallery")))
                  flash[:success] = "Gallery #{@gallery.name} was successfully updated!"
                  redirect_to user_gallery_path(@gallery.user, @gallery)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               points = (galleryValue(galleryFound) * 0.30).round
               galleryOwner = (owner && galleryFound.user.startgame)
               
               #Deletes the gallery
               if(staff || galleryOwner)
                  if(!staff && logged_in.galleries.count > 1)
                     galleryFound.user.pouch.amount += points
                     @pouch = galleryFound.user.pouch
                     @pouch.save
                     economyTransaction("Source", points, galleryFound.user.id, "Points")
                  end
                  
                  @gallery.destroy
                  flash[:success] = "Gallery #{@gallery.name} was successfully removed!"
                  
                  if(staff)
                     redirect_to galleries_list_path
                  else
                     redirect_to user_galleries_path(galleryFound.user)
                  end
               else
                  flash[:error] = "Gallery owner #{galleryFound.user.vname} has not activated their game yet!"
                  redirect_to root_path
               end
            end
         else
            if(!galleryFound)
               flash[:error] = "The gallery does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this gallery!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         price = Fieldcost.find_by_name("Gallery")
         user = (logged_in) #&& logged_in.gameinfo.startgame && (logged_in.galleries.count == 0 || (logged_in.pouch.amount - price.amount >= 0)))
         if(user)
            #Creates a new gallery for the user
            newGallery = logged_in.galleries.new
            if(type == "create")
               newGallery = logged_in.galleries.new(getGalleryParams("Gallery"))
               newGallery.created_on = currentTime
               newGallery.updated_on = currentTime
            end
            
            @user = logged_in
            @gallery = newGallery
            
            if(type == "create")
               if(@gallery.save)
                  if(logged_in.galleries.count > 0)
                     #Decrements the user's pouch
                     #logged_in.pouch.amount -= price.amount
                     #@pouch = logged_in.pouch
                     #@pouch.save
                     
                     #Applies a tax rate to the price of the user goods.
                     #rate = Ratecost.find_by_name("Purchaserate")
                     #tax = (price.amount * rate.amount)
                     #hoard = Dragonhoard.find_by_id(1)
                     #hoard.profit += tax
                     #@hoard = hoard
                     #@hoard.save
                     
                     #Keeps track of the economy
                     #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                     #economyTransaction("Tax", tax, logged_in.id, "Points")
                  end
                  
                  flash[:success] = "Gallery #{@gallery.name} was successfully created!"
                  redirect_to user_gallery_path(@user, @gallery)
               else
                  render "new"
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can create galleries!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "User #{logged_in.vname} can't afford the gallery create price!"
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
               if(type == "index")
                  indexpage
               elsif(type == "show")
                  showpage
               elsif(type == "music")
                  activateIntroVideo
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
            if(type == "index")
               indexpage
            elsif(type == "show")
               showpage
            elsif(type == "music")
               activateIntroVideo
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
               #Guests
               callMaintenance(type)
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy" || type == "music")
               #Login only
               callMaintenance(type)
            elsif(type == "list")
               #Staff only
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Reviewer"))
               if(staff)
                  allGalleries = Gallery.order("updated_on desc, created_on desc")
                  @galleries = allGalleries.page(getGalleryParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         end
      end
end
