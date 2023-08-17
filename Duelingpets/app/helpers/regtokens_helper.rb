module RegtokensHelper

   private
      def getRegtokenParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "Regtoken")
            value = params[:regtoken]
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
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
                  allRegtokens = Regtoken.order("expiretime desc")
                  @regtokens = Kaminari.paginate_array(allRegtokens).page(getRegtokenParams("Page")).per(50)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "gentoken")
               #Staff only
               logged_in = current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  newToken = Regtoken.new(getRegtokenParams("Regtoken"))
                  newToken.expiretime = 1.week.from_now.utc
                  newToken.token = SecureRandom.urlsafe_base64
                  @regtoken = newToken
                  @regtoken.save
                  flash[:success] = "Token was successfully created!"
                  redirect_to regtokens_path
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "regentoken" || type == "destroy")
               #Staff only
               logged_in = current_user
               tokenFound = Regtoken.find_by_id(getRegtokenParams("Id"))
               staff = (logged_in && tokenFound && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster"))
               
               if(staff)
                  if(type == "regentoken")
                     tokenFound.token = SecureRandom.urlsafe_base64
                     tokenFound.expiretime = 1.week.from_now.utc
                  end
                  
                  @regtoken = tokenFound
                  
                  if(type == "regentoken")
                     @regtoken.save
                     flash[:success] = "Token was successfully reset!"
                  else
                     @regtoken.destroy
                     flash[:success] = "Token was successfully removed!"
                  end
                  redirect_to regtokens_path
               else
                  if(!tokenFound)
                     flash[:error] = "Regtoken does not exist!"
                  else
                     flash[:error] = "This page is restricted to Staff only!"
                  end
                  redirect_to root_path
               end
            end
         end
      end
end
