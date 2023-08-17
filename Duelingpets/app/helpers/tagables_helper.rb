module TagablesHelper

   private
      def getTagableParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "TagableId")
            value = params[:tagable_id]
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
   
      def displayTags(type, id)
         tags = Tagable.select{|tag| tag.table_type == type && tag.table_id == id}
         owner = nil
         staff = (current_user && current_user.pouch.privilege == "Admin" || current_user.pouch.privilege = "Keymaster")
         if(type == "Chapter")
            chapter = Chapter.find_by_id(id)
            owner = current_user && current_user.id == chapter.user_id
         end
         tags.each do |tagable|
            if(staff || owner)
               content_tag(:div, tagable.tag.name + link_to("X", tagables_removetag_path(:table_type=>type, :table_id=>id, :tag_id=>tagable.tag.id), method: :post, class: "button destroybutton"), class: "")
            else
               content_tag(:div, tagable.tag.name, class: "")
            end
         end
      end
      
      def tagCommons(type)
         if(type == "addtag")
            #Setups the variables to be used for adding tags
            logged_in = current_user
            tagFound = Tag.find_by_name(params[:tagable][:name])
            tableType = params[:tagable][:table_type]
            tableId = params[:tagable][:table_id]
            tagValue = Tagable.find{|tagable| tagable.tag_id == tagFound.id && tagable.table_type == tableType && tagable.table_id == tableId}
            contentFound = nil
            
            #Determines the type of content to apply the tag to
            if(tableType && tableId && tagFound && tagValue.count == 0)
               if(tableType == "Chapter")
                  contentFound = Chapter.find_by_id(tableId)
               elsif(tableType == "Movie")
                  contentFound = Movie.find_by_id(tableId)
               elsif(tableType == "Art")
                  contentFound = Art.find_by_id(tableId)
               elsif(tableType == "Sound")
                  contentFound = Sound.find_by_id(tableId)
               end
            end
            
            staff = (logged_in && contentFound && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
            owner = nil
            if(contentFound)
               owner = (logged_in && contentFound && logged_in.id == contentFound.user_id)
            end
            
            if(staff || owner)
               #Price how much? 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
               price = 30
               if(staff || logged_in.pouch.amount - price >= 0)
                  if(!staff)
                     logged_in.pouch.amount -= price
                     @pouch = logged_in.pouch
                     @pouch.save
                     
                     #Send the funds to the central bank
                     rate = Ratecost.find_by_name("Purchaserate")
                     tax = (price * rate.amount)
                     hoard = Dragonhoard.find_by_id(1)
                     hoard.profit += tax
                     @hoard = hoard
                     @hoard.save
                     
                     #Keeps track of the economy
                     economyTransaction("Sink", price, contentFound.user.id, "Points")
                     economyTransaction("Tax", tax, contentFound.user.id, "Points")
                  end
                  newTagable = Tagable.new(params[:tagable])
                  newTagable.table_type = tableType
                  newTagable.table_id = tableId
                  newTagable.tag_id = tagFound.id
                  @tagable = newTagable
                  @tagable.save
                  flash[:success] = "Tag #{tagFound.name} was added to the #{tableType}!"
                  if(tableType == "Chapter")
                     redirect_to book_chapter_path(contentFound.book, contentFound)
                  elsif(tableType == "Movie")
                     redirect_to subplaylist_movie_path(contentFound.subplaylist, contentFound)
                  elsif(tableType == "Art")
                     redirect_to subfolder_art_path(contentFound.subfolder, contentFound)
                  elsif(tableType == "Sound")
                     redirect_to subsheet_sound_path(contentFound.subsheet, contentFound)
                  end
               else
                  flash[:error] = "User #{logged_in.vname} can't afford the add tag price!"
                  redirect_to root_path
               end
            else
               if(!contentFound)
                  flash[:error] = "The content does not exist!"
               else
                  flash[:error] = "Only the staff or the content owner can add tags!"
               end
               redirect_to root_path
            end
         else
            #Setups the variables to be used for adding tags
            logged_in = currrent_user
            tagableFound = Tagable.find_by_id(params[:id])
            contentFound = nil
            
            #Determines the content the tag is applied to
            if(tagableFound && tagableFound.table_type == "Chapter")
               contentFound = Chapter.find_by_id(tagableFound.table_id)
            elsif(tagableFound && tagableFound.table_type == "Movie")
               contentFound = Movie.find_by_id(tagableFound.table_id)
            elsif(tagableFound && tagableFound.table_type == "Art")
               contentFound = Art.find_by_id(tagableFound.table_id)
            elsif(tagableFound && tagableFound.table_type == "Sound")
               contentFound = Sound.find_by_id(tagableFound.table_id)
            end
            
            owner = (logged_in && contentFound && logged_in.id == contentFound.user_id)
            staff = (logged_in && contentFound && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
            price = 10
            if(staff || owner && logged_in.pouch.amount - price >= 0)
               if(!staff)
                  logged_in.pouch.amount -= price
                  @pouch = logged_in.pouch
                  @pouch.save
                  economyTransaction("Sink", price, contentFound.user.id, "Points")
               end
               flash[:success] = "Tag #{tagableFound.tag.name} was successfully removed!"
               @tagable = tagableFound
               @tagable.destroy
               if(staff)
                  if(type == "Chapter")
                     redirect_to chapters_path
                  elsif(type == "Movie")
                     redirect_to movies_path
                  elsif(type == "Art")
                     redirect_to arts_path
                  elsif(type == "Sound")
                     redirect_to sounds_path
                  end
               else
                  if(type == "Chapter")
                     redirect_to book_chapter_path(contentFound.book, contentFound)
                  elsif(type == "Movie")
                     redirect_to subplaylist_movie_path(contentFound.subplaylist, contentFound)
                  elsif(type == "Art")
                     redirect_to subfolder_art_path(contentFound.subfolder, contentFound)
                  elsif(type == "Sound")
                     redirect_to subsheet_sound_path(contentFound.subsheet, contentFound)
                  end
               end
            else
               if(!contentFound)
                  flash[:error] = "The content does not exist!"
               elsif(!staff && !owner)
                  flash[:error] = "Only the staff or the content owner can remove tags!"
               else
                  flash[:error] = "User #{logged_in.vname} can't afford the remove tag price!"
               end
               redirect_to root_path
            end
         end
      end
      
      def mode(type)
         if(type == "index")
            if(timeExpired)
               logoutUser("Single")
               redirect_to root_path
            else
               logoutUser("Multi")
               staff = (current_user && current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Keymaster")
               if(staff)
                  allTagables = Tagable.all
                  @tagables = Kaminari.paginate_array(allTagables).page(getTagableParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            end
         elsif(type == "addtag" || type == "removetag")
            allMode = Maintenancemode.find_by_id(1)
            userMode = Maintenancemode.find_by_id(6)
            if(allMode.maintenance_on || userMode.maintenance_on)
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
               if(staff)
                  tagCommons(type)
               else
                  if(allMode.maintenance_on)
                     render "/start/maintenance"
                  else
                     render "/users/maintenance"
                  end
               end
            else
               tagCommons(type)
            end
         end
      end
end
