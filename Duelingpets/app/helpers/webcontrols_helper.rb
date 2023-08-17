module WebcontrolsHelper

   private
      def getWebcontrolParams(type)
         value = ""
         if(type == "Webcontrol")
            value = params.require(:webcontrol).permit(:banner, :remote_banner_url, :banner_cache, :mascot, 
         :remote_mascot_url, :mascot_cache, :favicon, :remote_favicon_url, :favicon_cache,
         :criticalogg, :remote_criticalogg_url, :criticalogg_cache, :criticalmp3, 
         :remote_criticalmp3_url, :criticalmp3_cache, :betaogg, :remote_betaogg_url,
         :betaogg_cache, :betamp3, :remote_betamp3_url, :betamp3_cache, :grandogg,
         :remote_grandogg_url, :grandogg_cache, :grandmp3, :remote_grandmp3_url,
         :grandmp3_cache, :ogg, :remote_ogg_url, :ogg_cache, :mp3, :remote_mp3_url, :mp3_cache,
         :creationogg, :remote_creationogg_url, :creationogg_cache, :creationmp3,
         :remote_creationmp3_url, :creationmp3_cache, :missingpageogg, :remote_missingpageogg_url,
         :missingpageogg_cache, :missingpagemp3, :remote_missingpagemp3_url, :missingpagemp3_cache,
         :maintenanceogg, :remote_maintenanceogg_url, :maintenanceogg_cache, :maintenancemp3,
         :remote_maintenancemp3_url, :maintenancemp3_cache, :daycolor_id, :nightcolor_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def editCommons(type)
         logged_in = current_user
         webpanel = Webcontrol.find_by_id(1)
         staff = (logged_in && webpanel && logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Keymaster")

         if(staff)
            @webcontrol = webpanel
            
            if(type == "update")
               if(@webcontrol.update_attributes(getWebcontrolParams("Webcontrol")))
                  flash[:success] = "Staff #{logged_in.vname} made changes to the webpanel!"
                  redirect_to webcontrols_path
               else
                  render "edit"
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
                  allWebcontrols = Webcontrol.order("created_on desc")
                  @webcontrols = Kaminari.paginate_array(allWebcontrols).page(getWebcontrolParams("Page")).per(30)
               else
                  flash[:error] = "This page is restricted to Staff only!"
                  redirect_to root_path
               end
            elsif(type == "edit" || type == "update")
               #Staff only
               editCommons(type)
            end
         end
      end
end
