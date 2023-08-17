module PermissionsHelper

   private
      def current_user
         userPouch = Pouch.find_by_remember_token(cookies[:remember_token])
         if(userPouch)
            @current_user ||= User.find_by_vname(userPouch.user.vname)
         else
            @current_user
         end
      end
      
      def current_user=(user)
         @current_user = user
      end
      
      def userPrivilege(user)
         #Determines the areas the user can access
         privilege = "~"
         if(user.pouch.privilege == "Admin")
            privilege = "A$"
         elsif(user.pouch.privilege == "Keymaster")
            privilege = "$"
         elsif(user.pouch.privilege == "Betawriter")
            privilege = "B^"
         elsif(user.pouch.privilege == "Reviewer")
            privilege = "^"
         elsif(user.pouch.privilege == "Beta")
            privilege = "%"
         elsif(user.pouch.privilege == "Trial")
            privilege = "?"
         elsif(user.pouch.privilege == "Banned")
            privilege = "!"
         end
         return privilege
      end

      def checkUser(privilege)
         normal = (privilege != "Admin" && privilege != "Glitchy" && privilege != "Bot" && privilege != "Trial")
         return normal
      end

      def profileLinks
         if(current_user)
            link1 = content_tag(:p, link_to(current_user.vname, current_user) + " | " + link_to("Logout", logout_path, method: "delete"))
            #tag.br
            link2 = content_tag(:p, getClock)
            profile = link1 + link2
            #content_tag(:p, link_to(current_user.vname, current_user) + " | " + link_to("Logout", logout_path, method: "delete"))
            #content_tag(:p, getClock)
         else
            tag.p(("~Guest | " + link_to("Login", login_path)).html_safe)
            #Works
            #profile = content_tag(:p, ("~Guest | " + link_to("Login", login_path)).html_safe)
            #Works
            #profile = ("~Guest | " + link_to("Login", login_path)).html_safe
         end
      end
      
      def activity(type)
         #Displays the total users using the website
         allUsers = Pouch.all
         #hidden = ("Admin" || "Glitchy" || "Bot" || "Trial")
         hidden = ("Bot")
         totalUsers = allUsers.select{|pouch| pouch.activated && checkUser(pouch.privilege)}
         if(type == "Active")
            active = allUsers.select{|pouch| pouch.activated && checkUser(pouch.privilege) && !pouch.signed_out_at && pouch.last_visted && (currentTime - pouch.last_visited) < 8.minutes}
            userCount = active.count.to_s + "/" + totalUsers.count.to_s
         elsif(type == "Online")
            online = allUsers.select{|pouch| pouch.activated && checkUser(pouch.privilege) && !pouch.signed_out_at && pouch.last_visted && (currentTime - pouch.last_visited) >= 8.minutes && (currentTime - pouch.last_visited) < 17}
            userCount = online.count.to_s + "/" + totalUsers.count.to_s
         elsif(type == "Inactive")
            inactive = allUsers.select{|pouch| pouch.activated && checkUser(pouch.privilege) && !pouch.signed_out_at && pouch.last_visted && (currentTime - pouch.last_visited) >= 17.minutes}
            userCount = inactive.count.to_s + "/" + totalUsers.count.to_s
         elsif(type == "Register")
            userCount = Registration.all.count
         end
         return userCount
      end
end
