module DifficultiesHelper

   private
      def getDifficultyParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Difficulty")
            value = params.require(:difficulty).permit(:name, :pointdebt, :pointloan, :emeralddebt, :emeraldloan)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def editCommons(type)
         logged_in = current_user
         difficultyFound = Difficulty.find_by_id(getDifficultyParams("Id"))
         staff = (logged_in && difficultyFound && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         if(staff)
            @difficulty = difficultyFound
            if(type == "update")
               if(@difficulty.update_attributes(getDifficultyParams("Difficulty")))
                  flash[:success] = "Difficulty #{difficultyFound.name} was successfully updated!"
                  redirect_to difficulties_path
               else
                  render "edit"
               end
            elsif(type == "destroy")
               @difficulty.destroy
               flash[:success] = "Difficulty #{difficultyFound.name} was successfully removed!"
               redirect_to difficulties_path
            end
         else
            if(difficultyFound)
               flash[:error] = "The difficulty level does not exist!"
            else
               flash[:error] = "User doesn't have permission to edit this difficulty level!"
            end
            redirect_to root_path
         end
      end

      def createCommons(type)
         logged_in = current_user
         staff = (logged_in && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")
         if(staff)
            newDifficulty = Difficulty.new
            if(type == "create")
               newDifficulty = Difficulty.new(getDomainParams("Difficulty"))
               newDifficulty.created_on = currentTime
            end
            @difficulty = newDifficulty
            if(type == "create")
               if(@difficulty.save)
                  flash[:success] = "Difficulty #{@difficulty.name} was successfully created!"
                  redirect_to difficulties_path
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
                  allDifficulties = Difficulty.order("created_on desc")
                  @difficulties = Kaminari.paginate_array(allDifficultiess).page(getDifficultyParams("Page")).per(10)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "new" || type == "create")
               #Staff only
               createCommons(type)
            elsif(type == "edit" || type == "update" || type == "destroy")
               #Staff only
               editCommons(type)
            end
         end
      end
end
