module SuggestionsHelper

   private
      def getSuggestionParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Suggestion")
            value = params.require(:suggestion).permit(:title, :description)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end

      def mySuggestions
         logged_in = current_user
               
         if(logged_in)
            #Displays the user's suggestions
            allSuggestions = Suggestion.order("updated_on desc, created_on desc").select{|suggestion| suggestion.user_id == logged_in.id}
            @suggestions = Kaminari.paginate_array(allSuggestions).page(getSuggestionParams("Page")).per(30)
         else
            flash[:error] = "Only logged in users can access this page!"
            redirect_to root_path
         end
      end

      def editCommons(type)
         #Staff and Suggestion owner
         logged_in = current_user
         suggestionFound = Suggestion.find_by_id(getSuggestionParams("Id"))
         staff = (logged_in && suggestionFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
         owner = (logged_in && suggestionFound && logged_in.id == suggestionFound.user_id)
         
         if(staff || owner)
            suggestionFound.updated_on = currentTime
            @suggestion = suggestionFound
            @user = User.find_by_vname(ocFound.user.vname)
            if(type == "update")
               if(@suggestion.update_attributes(getSuggestionParams("Suggestion")))
                  flash[:success] = "Suggestion #{@suggestion.title} was successfully updated!"
                  if(staff)
                     redirect_to suggestions_path
                  else
                     redirect_to suggestions_mysuggestions_path
                  end
               else
                  render "edit"
               end
            elsif(type == "destroy")
               price = Fieldcost.find_by_name("Suggestioncleanup")
               owner = (suggestionOwner && suggestionFound.user.startgame && suggestionFound.user.pouch.amount - price.amount >= 0)
               if(staff || owner)
                  if(!staff)
                     #Decrements the points from the user's pouch
                     logged_in.pouch.amount -= price.amount
                     @pouch = logged_in.pouch.amount
                     @pouch.save
                     economyTransaction("Sink", price.amount, logged_in.id, "Points")
                  end
                  @suggestion.destroy
                  flash[:success] = "Suggestion #{@suggestion.name} was successfully removed!"
                  if(staff)
                     redirect_to suggestions_path
                  else
                     redirect_to suggestions_mysuggestions_path
                  end
               else
                  if(!suggestionFound.user.startgame)
                     flash[:error] = "Suggestion owner #{suggestionFound.user.vname} has not activated their game yet!"
                  else
                     flash[:error] = "Suggestion owner #{suggestionFound.user.vname} can't afford the removal price!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!suggestionFound)
               flash[:error] = "The suggestion does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this suggestion!"
            end
            redirect_to root_path
         end
      end
      
      def createCommons(type)
         #Creates a suggestion if the user is logged in
         logged_in = current_user
         if(logged_in && logged_in.gameinfo.startgame)
            newSuggestion = logged_in.suggestions.new
            if(type == "create")
               #Builds a new suggestion for the user
               newSuggestion = logged_in.suggestions.new(getSuggestionParams("Suggestion"))
               newSuggestion.created_on = currentTime
               newSuggestion.updated_on = currentTime
            end
            
            @suggestion = newSuggestion
            @user = logged_in
            
            if(type == "create")
               if(@suggestion.save)
                  #Adds the points to the user's pouch
                  suggestion = Fieldcost.find_by_name("Suggestion")
                  logged_in.pouch.amount += suggestion.amount
                  @pouch = logged_in.pouch
                  @pouch.save

                  #Updates the economy
                  economyTransaction("Source", suggestion.amount, newSuggestion.user_id, "Points")
                  ContentMailer.content_created(@suggestion, "Suggestion", suggetion.amount).deliver_now
                  flash[:success] = "Suggestion #{@suggestion.title} was successfully created!"
                  redirect_to suggestions_path
               else
                  render "new"
               end
            end
         else
            flash[:error] = "Only logged in users can create suggestions!"
            redirect_to root_path
         end
      end
      
      def callMaintenance(type)
         #removeTransactions
         allMode = Maintenancemode.find_by_id(1)
         ocMode = Maintenancemode.find_by_id(8)
         if(allMode.maintenance_on || ocMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Reviewer"))
            if(staff)
               if(type == "mysuggestions")
                  mySuggestions
               elsif(type == "new" || type == "create")
                  createCommons(type)
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
            if(type == "mysuggestions")
               mySuggestions
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
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  allSuggestions = Suggestion.order("updated_on desc, created_on desc")
                  @suggestions = Kaminari.paginate_array(allSuggestions).page(getSuggestionParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy" || type == "mysuggestions")
               #Login only
               callMaintenance(type)
            end
         end
      end
end
