module BookworldsHelper

   private
      def getBookworldParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "BookworldId")
            value = params[:bookworld_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Bookworld")
            value = params.require(:bookworld).permit(:name, :description, :open_world, :privateworld, :price)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def economyTransaction(type, points, userid, currency)
         newTransaction = Economy.new(params[:economy])
         #Determines the type of attribute to return
         if(type == "Sink")
            newTransaction.econattr = "Purchase"
         elsif(type == "Tax")
            newTransaction.econattr = "Treasury"
         elsif(type == "Source")
            newTransaction.econattr = "Fund"
         end
         newTransaction.content_type = "Bookworld"
         newTransaction.econtype = type
         newTransaction.amount = points
         #Currency can be either Points, Emeralds or Skildons
         newTransaction.currency = currency
         if(type != "Tax")
            newTransaction.user_id = userid
         else
            newTransaction.dragonhoard_id = 1
         end
         newTransaction.created_on = currentTime
         @economytransaction = newTransaction
         @economytransaction.save
      end
      
      def bookworldValue(bookworldFound)
         bookworld = Fieldcost.find_by_name("Bookworld")
         chapter = Fieldcost.find_by_name("Chapter")
         allBooks = Book.all
         books = allBooks.select{|book| book.bookworld_id == bookworldFound.id}
         allChapters = Chapter.all
         chapters = allChapters.select{|chapter| chapter.reviewed && chapter.book.bookworld_id == bookworldFound.id}
         points = (bookworld.amount + (books.count * bookworldFound.price) + (chapters.count * chapter.amount))
         return points
      end

      def displayStory(bookworld, type)
         book = nil

         #Displays the videos when the index page is open
         if(type == "index" && bookworld.books.count > 0)
            book = bookworld.books.order("updated_on desc", "created_on desc").first
            #chapter = book.chapters.order("updated_on desc", "created_on desc").first
         end

         #Displays the videos when the show page is open
         if(type == "show" && bookworld.chapters.count > 0)
            chapter = bookworld.chapters.order("updated_on desc", "created_on desc").first
            book = chapter
         end
         #   subplaylist = channel.subplaylists.order("updated_on desc", "created_on desc").first
         #   movie = subplaylist.movies.order("updated_on desc", "created_on desc").first
         #end

         #Displays the videos when the subplaylist is open
         #if(type == "subplaylist" && channel.movies.count > 0)
         #   movie = channel.movies.order("updated_on desc", "created_on desc").first
         #end

         #Displays the video when the movie is open
         #if(type == "movie")
         #   movie = channel
         #end
         return book
      end

      def indexCommons
         bookworlds = ""
         if(optional)
            userFound = User.find_by_vname(optional)
            if(userFound)
               userBookworlds = userFound.bookworlds.order("updated_on desc, created_on desc")
               bookworlds = userBookworlds
               @user = userFound
            else
               render "webcontrols/missingpage"
            end
         else
            allBookworlds = Bookworld.order("updated_on desc, created_on desc")
            bookworlds = allBookworlds
         end
         @bookworlds = Kaminari.paginate_array(bookworlds).page(getBookworldParams("Page")).per(10)
      end

      def optional
         value = getBookworldParams("User")
         return value
      end

      def editCommons(type)
         bookworldFound = Bookworld.find_by_name(getBookworldParams("Id"))
         if(bookworldFound)
            logged_in = current_user
            if(logged_in && ((logged_in.id == bookworldFound.user_id) || logged_in.pouch.privilege == "Admin"))
               bookworldFound.updated_on = currentTime
               @bookworld = bookworldFound
               @user = User.find_by_vname(bookworldFound.user.vname)
               if(type == "update")
                  if(@bookworld.update_attributes(getBookworldParams("Bookworld")))
                     flash[:success] = "Bookworld #{@bookworld.name} was successfully updated."
                     redirect_to user_bookworld_path(@bookworld.user, @bookworld)
                  else
                     render "edit"
                  end
               end
            else
               redirect_to root_path
            end
         else
            render "webcontrols/missingpage"
         end
      end

      def showCommons(type)
         bookworldFound = Bookworld.find_by_name(getBookworldParams("Id"))
         if(bookworldFound)
            removeTransactions
            @bookworld = bookworldFound
            books = bookworldFound.books
            @books = Kaminari.paginate_array(books).page(getBookworldParams("Page")).per(10)
            if(type == "destroy")
               logged_in = current_user
               if(logged_in && ((logged_in.id == bookworldFound.user_id) || logged_in.pouch.privilege == "Admin"))
                  if(bookworldFound.user.gameinfo.startgame)
                     #Gives the user points back for selling their bookworld
                     points = (bookworldValue(bookworldFound) * 0.30).round
                     bookworldFound.user.pouch.amount += points
                     @pouch = bookworldFound.user.pouch
                     @pouch.save
                     economyTransaction("Source", points, bookworldFound.user.id, "Points")
                     @bookworld.destroy
                     flash[:success] = "#{@bookworld.name} was successfully removed."
                     if(logged_in.pouch.privilege == "Admin")
                        redirect_to bookworlds_list_path
                     else
                        redirect_to user_bookworlds_path(bookworldFound.user)
                     end
                  else
                     if(logged_in.pouch.privilege == "Admin")
                        flash[:error] = "The writer has not activated the game yet!"
                        redirect_to bookworlds_list_path
                     else
                        flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                        redirect_to edit_gameinfo_path(logged_in.gameinfo)
                     end
                  end
               else
                  redirect_to root_path
               end
            end
         else
            render "webcontrols/missingpage"
         end
      end
      
      def mode(type)
         if(timeExpired)
            logoutUser("Single")
            redirect_to root_path
         else
            logoutUser("Multi")
            if(type == "index")
               removeTransactions
               allMode = Maintenancemode.find_by_id(1)
               bookworldMode = Maintenancemode.find_by_id(12)
               if(allMode.maintenance_on || bookworldMode.maintenance_on)
                  if(current_user && current_user.pouch.privilege == "Admin")
                     indexCommons
                  else
                     if(allMode.maintenance_on)
                        render "/start/maintenance"
                     else
                        render "/bookworlds/maintenance"
                     end
                  end
               else
                  indexCommons
               end
            elsif(type == "new" || type == "create")
               allMode = Maintenancemode.find_by_id(1)
               bookworldMode = Maintenancemode.find_by_id(12)
               if(allMode.maintenance_on || bookworldMode.maintenance_on)
                  if(allMode.maintenance_on)
                     render "/start/maintenance"
                  else
                     render "/bookworlds/maintenance"
                  end
               else
                  logged_in = current_user
                  userFound = User.find_by_vname(getBookworldParams("User"))
                  if(logged_in && userFound)
                     if(logged_in.id == userFound.id)
                        newBookworld = logged_in.bookworlds.new
                        if(type == "create")
                           newBookworld = logged_in.bookworlds.new(getBookworldParams("Bookworld"))
                           newBookworld.created_on = currentTime
                           newBookworld.updated_on = currentTime
                        end

                        @bookworld = newBookworld
                        @user = userFound

                        if(type == "create")
                           price = Fieldcost.find_by_name("Bookworld")
                           rate = Ratecost.find_by_name("Purchaserate")
                           tax = (price.amount * rate.amount)
                           if(logged_in.pouch.amount - price.amount >= 0)
                              if(logged_in.gameinfo.startgame)
                                 if(@bookworld.save)
                                    logged_in.pouch.amount -= price.amount
                                    @pouch = logged_in.pouch
                                    @pouch.save
                                    hoard = Dragonhoard.find_by_id(1)
                                    hoard.profit += tax
                                    @hoard = hoard
                                    @hoard.save
                                    economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                                    economyTransaction("Tax", tax, logged_in.id, "Points")
                                    flash[:success] = "#{@bookworld.name} was successfully created."
                                    redirect_to user_bookworld_path(@user, @bookworld)
                                 else
                                    render "new"
                                 end
                              else
                                 flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                                 redirect_to edit_gameinfo_path(logged_in.gameinfo)
                              end
                           else
                              flash[:error] = "Insufficient funds to create bookworld!"
                              redirect_to root_path
                           end
                        end
                     else
                        redirect_to root_path
                     end
                  else
                     redirect_to root_path
                  end
               end
            elsif(type == "edit" || type == "update")
               if(current_user && current_user.pouch.privilege == "Admin")
                  editCommons(type)
               else
                  allMode = Maintenancemode.find_by_id(1)
                  bookworldMode = Maintenancemode.find_by_id(12)
                  if(allMode.maintenance_on || bookworldMode.maintenance_on)
                     if(allMode.maintenance_on)
                        render "/start/maintenance"
                     else
                        render "/bookworlds/maintenance"
                     end
                  else
                     editCommons(type)
                  end
               end
            elsif(type == "show" || type == "destroy")
               allMode = Maintenancemode.find_by_id(1)
               bookworldMode = Maintenancemode.find_by_id(12)
               if(allMode.maintenance_on || bookworldMode.maintenance_on)
                  if(current_user && current_user.pouch.privilege == "Admin")
                     showCommons(type)
                  else
                     if(allMode.maintenance_on)
                        render "/start/maintenance"
                     else
                        render "/bookworlds/maintenance"
                     end
                  end
               else
                  showCommons(type)
               end
            elsif(type == "list")
               logged_in = current_user
               if(logged_in && logged_in.pouch.privilege == "Admin")
                  removeTransactions
                  allBookworlds = Bookworld.order("updated_on desc, created_on desc")
                  @bookworlds = allBookworlds.page(getBookworldParams("Page")).per(10)
               else
                  redirect_to root_path
               end
            elsif(type == "increase" || type == "decrease")
               bookworldFound = Bookworld.find_by_id(getBookworldParams("BookworldId"))
               logged_in = current_user
               if(bookworldFound && logged_in)
                  if(logged_in.pouch.privilege == "Admin" || logged_in.id == bookworldFound.user.id)
                     pointchange = 0
                     if(bookworldFound.user.gameinfo.startgame)
                        if(type == "increase")
                           pointchange = bookworldFound.price + 10
                        else
                           pointchange = bookworldFound.price - 10
                        end

                        #Saves the change to books price
                        if(pointchange < 0)
                           flash[:error] = "You can't set points below 0!"
                           redirect_to root_path
                        else
                           bookworldFound.price = pointchange
                           @bookworld = bookworldFound
                           @bookworld.save
                           flash[:success] = "Bookworld #{bookworld.name} price was successfully increased/decreased!"
                           redirect_to user_bookworld_path(@bookworld.user, @bookworld)
                        end
                     else
                        if(logged_in.pouch.privilege == "Admin")
                           flash[:error] = "The writer has not activated the game yet!"
                           redirect_to bookworlds_list_path
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
            end
         end
      end
end
