module DonationboxesHelper

   private
      def getDonationboxParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
          elsif(type == "DonationboxId")
            value = params[:donationbox_id]
         elsif(type == "Donationbox")
            value = params.require(:donationbox).permit(:description, :goal, :box_open)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def deactivateDonations(donationboxFound)
         #Deactivates the donationbox
         donationboxFound.goal = 0
         donationboxFound.progress = 0
         donationboxFound.hitgoal = false
         donationboxFound.box_open = false
         @user = donationboxFound.user
         @donationbox = donationboxFound
         @donationbox.save
         redirect_to user_path(@donationbox.user)
      end

      def donationRetrieve
         logged_in = current_user
         donationboxFound = Donationbox.find_by_id(getDonationboxParams("Id"))
         boxOwner = (logged_in && donationboxFound && logged_in.id == donationboxFound.user_id && donationboxFound.user.gameinfo.startgame && donationboxFound.hitgoal)
         if(boxOwner)
            #Calculate the tax
            points = donationboxFound.progress
            donationtax = Ratecost.find_by_name("Donationrate")
            taxinc = donationtax.amount
            results = `public/Resources/Code/dbox/calc #{points} #{taxinc}`
            string_array = results.split(",")
            pointsTax, taxRate = string_array.map{|str| str.to_f}

            #Send the points to the user's pouch
            pouch = Pouch.find_by_user_id(donationboxFound.user.id)
            netPoints = donationboxFound.progress - pointsTax
            economyTransaction("Source", netPoints, "Donationbox", pouch.user.id, "Points")
            economyTransaction("Tax", pointsTax, "Donationbox", "None", "Points")
            CommunityMailer.donations(donationboxFound, "Retrieve", netPoints, taxRate, pointsTax).deliver_now
            
            #Updates the user's on hand currency
            pouch.amount += netPoints
            @pouch = pouch
            @pouch.save
            hoard = Dragonhoard.find_by_id(1)
            hoard.profit += pointsTax
            @hoard = hoard
            @hoard.save
            
            deactivateDonations(donationboxFound)
         else
            if(!donationboxFound)
               flash[:error] = "The donationbox does not exist!"
            elsif(!logged_in || logged_in.id != donationboxFound.user_id)
               flash[:error] = "User doesn't have permission to refund this donationbox!"
            elsif(!donationboxFound.user.gameinfo.startgame)
               flash[:error] = "Box owner #{donationboxFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "You can't retrieve currency until you hit your donation goal!"
            end
            redirect_to root_path
         end
      end

      def donationRefund
         logged_in = current_user
         donationboxFound = Donationbox.find_by_id(getDonationboxParams("Id"))
         staff = (logged_in && donationboxFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         boxOwner = (logged_in && donationboxFound && logged_in.id == donationboxFound.user_id && donationboxFound.user.gameinfo.startgame && !donationboxFound.hitgoal)
         if(staff || boxOwner)
            allDonors = Donor.all
            boxDonors = allDonors.select{|donor| donor.donationbox_id == donationboxFound.id}
            activeDonors = boxDonors.select{|donor| donor.created_on > donationboxFound.initialized_on}
            
            #Gives back the original users donations
            activeDonors.each do |donor|
               donor.user.pouch.amount += donor.amount
               donationboxFound.progress -= donor.amount
               CommunityMailer.donations(donor, "Refund", donor.amount, 0, 0).deliver_now
               economyTransaction("Source", donor.amount, "Donor", donor.user.id, "Points")
               @tempbox = donationboxFound
               @tempbox.save
               @pouch = donor.user.pouch
               @pouch.save
               @donor = donor
               @donor.destroy
            end
            
            deactivateDonations(donationboxFound)
         else
            if(!donationboxFound)
               flash[:error] = "The donationbox does not exist!"
            elsif(!logged_in || logged_in.id != donationboxFound.user_id)
               flash[:error] = "User doesn't have permission to refund this donationbox!"
            elsif(!donationboxFound.user.gameinfo.startgame)
               flash[:error] = "Box owner #{donationboxFound.user.vname} has not activated their game yet!"
            else
               flash[:error] = "The donation goal was reached, only staff can refund currency!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff and Donationbox owner
         logged_in = current_user
         boxFound = Donationbox.find_by_id(getDonationboxParams("Id"))
         owner = (logged_in && boxFound && logged_in.id == boxFound.user_id && !boxFound.box_open)
         staff = (logged_in && boxFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         if(staff || owner)
            donationboxFound.initialized_on = currentTime
            @donationbox = donationboxFound
            @user = User.find_by_vname(donationboxFound.user.vname)
            if(type == "update")
               if(donationboxFound.goal <= donationboxFound.capacity)
                  if(@donationbox.update_attributes(getDonationboxParams("Donationbox")))
                     flash[:success] = "#{@donationbox.user.vname}'s donationbox was successfully updated."
                     redirect_to user_path(@donationbox.user)
                  else
                     render "edit"
                  end
               else
                  flash[:error] = "Donation goal can't exceed capacity of #{@donationbox.capacity} points!"
                  redirect_to root_path
               end
            end
         else
            if(!boxFound)
               flash[:error] = "The donationbox does not exist!"
            elsif(!logged_in || logged_in.id != boxFound.user_id)
               flash[:error] = "User doesn't have permission to edit this donationbox!"
            else
               flash[:error] = "The donationbox is currently activated!"
            end
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Keymaster"))
            if(staff)
               if(type == "retrieve")
                  donationRetrieve
               elsif(type == "refund")
                  donationRefund
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
            if(type == "retrieve")
               donationRetrieve
            elsif(type == "refund")
               donationRefund
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
                  allDonationboxes = Donationbox.order("initialized_on desc")
                  @donationboxes = Kaminari.paginate_array(allDonationboxes).page(getDonationboxParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "edit" || type == "update" || type == "retrieve" || type == "refund")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
