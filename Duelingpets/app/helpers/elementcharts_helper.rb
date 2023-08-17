module ElementchartsHelper

   private
      def getElementchartParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "ElementchartId")
            value = params[:elementchart_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Elementchart")
            value = params.require(:elementchart).permit(:name)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def indexpage
         userFound = User.find_by_vname(getElementchartParams("User"))
         if(userFound)
            userElementcharts = userFound.elementcharts.order("updated_on desc", "created_on desc")
            elementcharts = userElementcharts
            @user = userFound
         else
            allElementcharts = Elementchart.order("updated_on desc", "created_on desc")
            elementcharts = allElementcharts
         end
         @elementcharts = Kaminari.paginate_array(elementcharts).page(getElementchartParams("Page")).per(10)
      end
      
      def showpage
         #Staff, elementchartOwner and guests
         logged_in = current_user
         elementchartFound = Elementchart.find_by_id(getElementchartParams("Id"))
         staff = (logged_in && elementchartFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         elementchartOwner = (logged_in && elementchartFound && logged_in.id == elementchartFound.user_id)
         guests = elementchartFound
         if(staff || elementchartOwner || guests)
            @elementchart = elementchartFound
            #Powers, Weaknesses, Strengths
            elementchartFound.elementmaps.all
            @elementmaps = elementchartFound.elementmaps
         else
            flash[:error] = "The elementchart does not exist!"
            redirect_to root_path
         end
      end
      
      def editCommons(type)
         #Staff, and Elementchart owner
         logged_in = current_user
         elementchartFound = Elementchart.find_by_id(getElementchartParams("Id"))
         staff = (logged_in && elementchartFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Reviewer"))
         elementchartOwner = (logged_in && elementchartFound && logged_in.id == elementchartFound.user_id)
         if(staff || elementchartOwner)
            elementchartFound.updated_on = currentTime
            @elementchart = elementchartFound
            @user = User.find_by_vname(elementchartFound.user.vname)
            if(type == "update")
               if(@elementchart.update_attributes(getElementchartParams("Elementchart")))
                  flash[:success] = "Elementchart #{@elementchart.name} was successfully updated!"
                  redirect_to user_elementchart_path(@elementchart.user, @elementchart)
               else
                  render "edit"
               end
            elsif(type == "destroy")
               owner = (elementchartOwner) #&& elementchartFound.user.startgame)
               if(staff || owner)
                  if(!staff)
                     #points = (channelValue(channelFound) * 0.30).round
                     #channelFound.user.pouch.amount += points
                     #@pouch = channelFound.user.pouch
                     #@pouch.save
                     #economyTransaction("Source", points, channelFound.user.id, "Points")
                  end
                  @elementchart.destroy
                  flash[:success] = "Elementchart #{@elementchart.name} was successfully removed!"
                  if(staff)
                     #redirect_to elementcharts_list_path
                  else
                     redirect_to user_elementcharts_path(elementchartFound.user)
                  end
               else
                  flash[:error] = "Elementchart owner #{elementchartFound.user.vname} has not activated their game yet!"
                  redirect_to root_path
               end
            end
         else
            if(!elementchartFound)
               flash[:error] = "The elementchart does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this elementchart!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         logged_in = current_user
         #owner = (logged_in && userFound && logged_in.id == userFound.id) #&& userFound.gameinfo.startgame)
         #price = Fieldcost.find_by_name("Channel")
         if(logged_in) #&& userFound.pouch.amount - price.amount >= 0) #swap with emeralds later
            newElementchart = logged_in.elementcharts.new
            if(type == "create")
               newElementchart = logged_in.elementcharts.new(getElementchartParams("Elementchart"))
               newElementchart.created_on = currentTime
               newElementchart.updated_on = currentTime
            end
            @elementchart = newElementchart
            @user = logged_in
            if(type == "create")
               if(@elementchart.save)
                  #userFound.pouch.emeralds - price.amount #Need to swap with emeralds
                  #logged_in.pouch.amount -= price.amount
                  #@pouch = logged_in.pouch
                  #@pouch.save
                  
                  #Send the funds to the central bank
                  #rate = Ratecost.find_by_name("Purchaserate")
                  #tax = (price.amount * rate.amount)
                  #hoard = Dragonhoard.find_by_id(1)
                  #hoard.profit += tax
                  #@hoard = hoard
                  #@hoard.save
                  
                  #Keeps track of the economy
                  #economyTransaction("Sink", price.amount - tax, logged_in.id, "Points")
                  #economyTransaction("Tax", tax, logged_in.id, "Points")
                  flash[:success] = "Elementchart #{@elementchart.name} was successfully created!"
                  redirect_to user_elementchart_path(@user, @elementchart)
               else
                  render "new"
               end
            end
         else
            if(!logged_in)
               flash[:error] = "Only logged in users can create elementcharts!"
            #elsif(!userFound.gameinfo.startgame)
            #   flash[:error] = "User #{userFound.vname} has not activated their game yet!"
            #else
            #   flash[:error] = "User #{userFound.vname} can't afford the channel price!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6) #Might need to rethink this
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
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
                  render "/elementcharts/maintenance"
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
               #Guests
               callMaintenance(type)
            elsif(type == "show")
               #Guests
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            #elsif(type == "list")
               #Staff only
            #   staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Reviewer"))
            #   if(staff)
            #      allChannels = Channel.order("updated_on desc, created_on desc")
            #      @channels = allChannels.page(getChannelParams("Page")).per(10)
            #   else
            #      flash[:error] = "This page is restricted to Staff only!"
            #      redirect_to root_path
            #   end
            end
         end
      end
end
