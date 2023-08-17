module DonorsHelper

   private
      def getDonorParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "DonorId")
            value = params[:donor_id]
         elsif(type == "DonationboxId")
            value = params[:donationbox_id]
         elsif(type == "Donor")
            value = params.require(:donor).permit(:description, :amount)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def donationRefund
         #Staff and donationbox owner
         logged_in = current_user
         donationFound = Donor.find_by_id(getDonorParams("Id"))
         staff = (logged_in && donationFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         donationOwner = (logged_in && donationFound && logged_in.id == donationFound.user_id && logged_in.gameinfo.startgame)
         boxOwner = (logged_in && donationFound && logged_in.id == donationFound.donationbox.user_id && donationFound.donationbox.user.gameinfo.startgame)
         if(staff || boxOwner || donationOwner)
            #Should only be able to fire if the donation has not been approved yet!
            donationPoints = 0
            if(donationOwner)
               donationPoints = donationFound.amount * 0.60;
            else
               donationPoints = donationFound.amount
            end
            
            #Returns the points back to the donor and deletes the donation
            donationFound.user.pouch.amount += donationPoints
            donationFound.donationbox.progress -= donationFound.amount
            @donationbox = donationFound.donationbox
            @donationbox.save
            @pouch = donationFound.user.pouch
            @pouch.save
            @donor = donationFound
            @donor.destroy
            flash[:success] = "The donated points were returned to the owner!"
            redirect_to root_path
         else
            if(!donationFound)
               flash[:error] = "The donation does not exist!"
            elsif(!logged_in || logged_in.id != donationFound.user_id || logged_in.id != donationFound.donationbox.user_id)
               flash[:error] = "Only the donation owner or the box owner may refund donations!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "Donor #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "Box owner #{donationFound.donationbox.user.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def storeDonations(newDonor, donationboxFound, capacityLeft)
         @donor = newDonor
         @donationbox = donationboxFound
         if(@donor.save)
            if(capacityLeft >= 0)
               donationboxFound.progress += @donor.amount
            else
               donationboxFound.progress = donationboxFound.capacity
               #lostPoints = capacityLeft
            end
            
            #Sets the flag for retrieving donations
            goalAchieved = (donationboxFound.progress >= donationboxFound.goal && !donationboxFound.hitgoal)
            if(goalAchieved)
               donationboxFound.hitgoal = true
               profit = donationboxFound.progress - donationboxFound.goal
               CommunityMailer.donations(@donor, "Goal", profit, 0, points).deliver_now
            end
                     
            #Updates the donationbox changes
            @donationbox.save
            logged_in.pouch.amount -= @donor.amount
            @pouch = logged_in.pouch
            @pouch.save
            economyTransaction("Sink", @donor.amount, logged_in.id, "Points")
            flash[:success] = "#{@donor.user.vname}'s donation was successfully added!"
            CommunityMailer.donations(@donor, "Donated", @donor.amount, 0, 0).deliver_now
            redirect_to user_path(@donationbox.user)
         else
            render "new"
         end
      end
      
      def removeDonation
         #Staff and donationbox owner
         logged_in = current_user
         donationFound = Donor.find_by_id(getDonorParams("Id"))
         staff = (logged_in && donationFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         donationOwner = (logged_in && donationFound && logged_in.id == donationFound.user_id && logged_in.gameinfo.startgame)
         boxOwner = (logged_in && donationFound && logged_in.id == donationFound.donationbox.user_id && donationFound.donationbox.user.gameinfo.startgame)
         if(staff || boxOwner || donationOwner)
            #Should only happen if the donation has already been approved.
            @donor = donationFound
            @donor.destroy
            flash[:success] = "The donation was deleted!"
            redirect_to root_path
         else
            if(!donationFound)
               flash[:error] = "The donation does not exist!"
            elsif(!logged_in || logged_in.id != donationFound.user_id || logged_in.id != donationFound.donationbox.user_id)
               flash[:error] = "Only the donation owner or the box owner may refund donations!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "Donor #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "Box owner #{donationFound.donationbox.user.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         donationboxFound = Donationbox.find_by_id(getDonorParams("DonationboxId"))
         donor = (logged_in && donationboxFound && donationboxFound.box_open && logged_in.id != donationboxFound.user.id && logged_in.gameinfo.startgame)
         if(donor && donationboxFound.user.gameinfo.startgame)
            if(type == "new")
               newDonor = donationboxFound.donors.new
               @donationbox = donationboxFound
               @donor = newDonor
            else
               newDonor = donationboxFound.donors.new(getDonorParams("Donor"))
               newDonor.created_on = currentTime
               newDonor.updated_on = currentTime
               newDonor.user_id = logged_in.id
               atMaxPoints = (donationboxFound.capacity == donationboxFound.progress)
               validDonation = (logged_in.pouch.amount > 0 && logged_in.pouch.amount - newDonor.amount >= 0 && newDonor.amount <= newDonor.capacity)
               capacityLeft = (donationboxFound.capacity - donationboxFound.progress - newDonor.amount)
               if(validDonation && !atMaxPoints && capacityLeft >= 0)
                  storeDonations(newDonor, donationboxFound, capacityLeft)
               else
                  if(!validDonation)
                     if(newDonor.amount > newDonor.capacity)
                        flash[:error] = "You have exceeded the donor limit of #{newDonor.capacity} points!"
                     else
                        flash[:error] = "You can't send points that you don't have!"
                     end
                     redirect_to root_path
                  elsif(atMaxPoints)
                     flash[:error] = "The donationbox is full!"
                     redirect_to root_path
                  else
                     storeDonations(newDonor, donationboxFound, capacityLeft)
                  end
               end
            end
         else
            if(!donationboxFound)
               flash[:error] = "The donatiobox does not exist!"
            elsif(!donationboxFound.box_open)
               flash[:error] = "The donationbox is currently closed!"
            elsif(!logged_in)
               flash[:error] = "Only logged in users can donate points!"
            elsif(logged_in.id == donationboxFound.user.id)
               flash[:error] = "You can't donate points to yourself!"
            elsif(logged_in.gameinfo.startgame)
               flash[:error] = "Donor #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "Box owner #{donationboxFound.user.vname} has not activated their game yet!"
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
               if(type == "new" || type == "create")
                  createCommons(type)
               elsif(type == "refund")
                  donationRefund
               elsif(type == "delete")
                  removeDonation
               end
            else
               if(allMode.maintenance_on)
                  render "/start/maintenance"
               else
                  render "/users/maintenance"
               end
            end
         else
            if(type == "new" || type == "create")
               createCommons(type)
            elsif(type == "refund")
               donationRefund
            elsif(type == "delete")
               removeDonation
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
               #Staff
               logged_in == current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               if(staff)
                  allDonors = Donor.order("created_on desc")
                  @donors = Kaminari.paginate_array(allDonors).page(getDonorParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create" || type == "delete" || type == "refund")
               #Login only
               callMaintenance(type)
            end
         end
      end
end

#We need a cancel order
#We also need a delete completed orders button
