module FieldcostsHelper

   private
      def getFieldcostParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Fieldcost")
            value = params.require(:fieldcost).permit(:name, :econtype)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def priceChange(type)
         logged_in = current_user
         fieldcostFound = Fieldcost.find_by_id(getFieldcostParams("Id"))
         staff = (logged_in && fieldcostFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         glitchy = (logged_in && fieldcostFound && logged_in.pouch.privilege == "Glitchy" && logged_in.gameinfo.startgame)
         dragonhoard = Dragonhoard.find_by_id(1)
         price = ((fieldcostFound.amount + fieldcostFound.baseinc.amount) + dragonhoard.fieldprice * 0.45).round
         
         #Updates the price for the fieldcost
         if((staff || glitchy) && dragonhoard.treasury - price >= 0)
            msg = ""
            if(type == "decrease")
               if(fieldcostFound.amount - fieldcostFound.baseinc.amount >= 0)
                  fieldcostFound.amount -= fieldcostFound.baseinc.amount
               else
                  fieldcostFound.amount = 0
               end
               msg = "Fieldcost #{@fieldcost.name} was decremented!"
            else
               msg = "Fieldcost #{@fieldcost.name} was incremented!"
               fieldcostFound.amount += fieldcostFound.baseinc.amount
            end
            
            #Decrements the treasury when updating the price for the fieldcost
            dragonhoard.treasury -= price
            @hoard = hoard
            @hoard.save
            @fieldcost = fieldcostFound
            @fieldcost.save
            
            #Updates the economy
            economyTransaction("Sink", price, fieldcostFound, "Points")
            flash[:success] = msg
            
            if(staff)
               redirect_to fieldcosts_path
            else
               redirect_to dragonhoards_path
            end
         else
            if(!fieldcostFound)
               flash[:error] = "The fieldcost does not exist!"
            elsif(!logged_in || (logged_in.pouch.privilege != "Glitchy" && logged_in.pouch.privilege == "Admin" && logged_in.pouch.privilege != "Keymaster"))
               flash[:error] = "The user doesn't have permission to access this page!"
            elsif(!logged_in.gameinfo.startgame)
               flash[:error] = "User #{logged_in.vname} has not activated their game yet!"
            else
               flash[:error] = "The dragonhoard doesn't have enough currency to update the field!"
            end
         end
      end

      def editCommons(type)
         logged_in = current_user
         fieldcostFound = Fieldcost.find_by_id(getFieldcostParams("Id"))
         staff = (logged_in && fieldcostFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         if(staff)
            #Sets up the new increment that the fieldcost will update by
            fieldcostFound.updated_on = currentTime
            allBaseincs = Baseinc.order("created_on desc")
            @baseincs = allBaseincs
            @fieldcost = fieldcostFound
            
            if(type == "update")
               #Saves the changes of the fieldcost
               if(@fieldcost.update_attributes(getFieldcostParams("Fieldcost")))
                  flash[:success] = "Fieldcost #{@fieldcost.name} was successfully updated!"
                  redirect_to fieldcosts_path
               else
                  render "edit"
               end
            end
         else
            if(!fieldcostFound)
               flash[:error] = "The fieldcost does not exist!"
            else
               flash[:error] = "This page is restricted to Staff only!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         
         #Builds a new field value for user features
         if(staff)
            newFieldcost = Fieldcost.new
            if(type == "create")
               newFieldcost = Fieldcost.new(getFieldcostParams("Fieldcost"))
               newFieldcost.created_on = currentTime
               newFieldcost.updated_on = currentTime
            end
            
            #Sets up the increment at which the field increments by 
            allBaseincs = Baseinc.order("created_on desc")
            @baseincs = allBaseincs
            @fieldcost = newFieldcost
            
            if(type == "create")
               if(@fieldcost.save)
                  flash[:success] = "Fieldcost #{@fieldcost.name} was successfully created!"
                  redirect_to fieldcosts_path
               else
                  render "new"
               end
            end
         else
            flash[:error] = "This page is restricted to Staff only!"
            redirect_to root_path
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
                  allFieldcosts = Fieldcost.order("updated_on desc, created_on desc")
                  @fieldcosts = Kaminari.paginate_array(allFieldcosts).page(getFieldcostParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create")
               #Staff only
               createCommons(type)
            elsif(type == "edit" || type == "update")
               #Staff only
               editCommons(type)
            elsif(type == "increase" || type == "decrease")
               #Glitchy only
               priceChange(type)
            end
         end
      end
end
