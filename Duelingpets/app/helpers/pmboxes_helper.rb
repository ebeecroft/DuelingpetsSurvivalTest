module PmboxesHelper

   private
      def getBoxParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
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
               logged_in == current_user
               staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))

               if(staff)
                  allBoxes = Pmbox.order("id desc")
                  @pmboxes = Kaminari.paginate_array(allBoxes).page(getBoxParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "inbox" || type == "outbox")
               #Login only
               logged_in = current_user
               if(logged_in)
                  allPms = Pm.order("created_on desc")
                  pms = allPms.select{|pm| pm.pmbox_id == logged_in.pmbox.id || pm.pmreplies.count > 0}
                  if(type == "outbox")
                     pms = allPms.select{|pm| pm.user_id == logged_in.id}
                  end
                  @pms = Kaminari.paginate_array(pms).page(getBoxParams("Page")).per(30)
               else
                  flash[:error] = "Only logged in users can utilize this feature!"
                  redirect_to root_path
               end               
            end
         end
      end
end
