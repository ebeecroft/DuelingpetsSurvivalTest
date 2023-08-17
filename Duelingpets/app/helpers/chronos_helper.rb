module ChronosHelper

   private
      def currentTime
         Time.zone.now
      end
      
      def getClock
         #Displays the game clock to the user
         if(current_user && current_user.userinfo.militarytime)
            clockTime = currentTime.in_time_zone(current_user.country_timezone)
            clockTime.strftime("%H:%M:%S %Z")
         elsif(current_user)
            clockTime = currentTime.in_time_zone(current_user.country_timezone)
            clockTime.strftime("%I:%M:%S %p %Z")
         else
            #currentTime.strftime("%I:%M:%S %p %Z")
            #currentTime.strftime("%I:%M")
         end
      end
      
      def timeExpired
         outOfTime = false
         if(current_user && !current_user.pouch.expiretime.nil? && currentTime >= current_user.pouch.expiretime)
            outOfTime = true
         end
         return outOfTime
      end
      
      def clearToken(user)
         user.pouch.remember_token = "Cleared!"
         user.pouch.last_visited = nil
         logoutTime = currentTime
         if(timeExpired)
            logoutTime = user.pouch.expiretime
         end
         user.pouch.signed_out_at = logoutTime
         user.pouch.expiretime = nil
         @pouch = user.pouch
         @pouch.save
      end
      
      def logoutUser(type)
         if(type == "Single" && current_user)
            clearToken(current_user)
            flash[:success] = "Good night #{current_user.vname} we will see you tomorrow. Sweet dreams!"
            cookies.delete(:remember_token)
            self.current_user = nil
         else
            users = User.order("joined_on desc").select{|user| !user.pouch.expiretime.nil? && (currentTime >= user.pouch.expiretime)}
            users.each do |user|
               clearToken(user)
            end
         end
      end
      
      def removeTransactions
         oldActivities = Economy.order("created_on desc").select{|activity| (currentTime - activity.created_on) > 1.day}
         oldActivities.each do |activity|
            @economy = activity
            @economy.destroy
         end
      end
end
