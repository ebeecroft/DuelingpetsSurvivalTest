module BlogsHelper

   private
      def getBlogParams(type)
         value = ""
         if(type == "Id")
            value = params[:id]
         elsif(type == "BlogId")
            value = params[:blog_id]
         elsif(type == "User")
            value = params[:user_id]
         elsif(type == "Blog")
            value = params.require(:blog).permit(:title, :description, :ogg, :remote_ogg_url, :ogg_cache,
            :mp3, :remote_mp3_url, :mp3_cache, :adbanner, :remote_adbanner_url, :adbanner_cache, :admascot,
            :remote_admascot_url, :admascot_cache, :largeimage1, :remote_largeimage1_url, :largeimage1_cache,
            :largeimage2, :remote_largeimage2_url, :largeimage2_cache, :largeimage3, :remote_largeimage3_url,
            :largeimage3_cache, :smallimage1, :remote_smallimage1_url, :smallimage1_cache, :smallimage2,
            :remote_smallimage2_url, :smallimage2_cache, :smallimage3, :remote_smallimage3_url,
            :smallimage3_cache, :smallimage4, :remote_smallimage4_url, :smallimage4_cache, :smallimage5,
            :remote_smallimage5_url, :smallimage5_cache, :bookgroup_id, :blogtype_id, :gviewer_id)
         elsif(type == "Page")
            value = params[:page]
         else
            raise "Invalid type detected!"
         end
         return value
      end
      
      def indexpage
         userFound = User.find_by_vname(getBlogParams("User"))
         if(userFound)
            userBlogs = userFound.blogs.order("reviewed_on desc, created_on desc")
            blogsReviewed = userBlogs.select{|blog| blog.reviewed || (current_user && blog.user_id == current_user.id)}
            @user = userFound
         else
            allBlogs = Blog.order("reviewed_on desc, created_on desc")
            blogsReviewed = allBlogs.select{|blog| blog.reviewed || (current_user && blog.user_id == current_user.id)}
         end
         @blogs = Kaminari.paginate_array(blogsReviewed).page(getBlogParams("Page")).per(10)
      end

      def showpage
         blogFound = Blog.find_by_id(getBlogParams("Id")) #Add bookgroup
         staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Betawriter"))
         blogValid = blogFound && (staff || (current_user && current_user.id == blogFound.user_id) || blog.reviewed)
         if(blogValid)
            @blog = blogFound
            blogReplies = @blog.blogreplies.order("created_on desc")
            replies = blogReplies.select{|blogreply| blogreply.reviewed || (current_user && blogreply.user_id == current_user.id)}
            @replies = Kaminari.paginate_array(replies).page(getBlogParams("Page")).per(6)
         else
            if(!blogFound)
               flash[:error] = "Blog doesn't exist!"
            elsif(!blogFound.reviewed)
               flash[:error] = "Blog is not accessible to guests!"
            end
         end
      end
      
      def adsPurchased(blogFound)
         smallpurchase1 = (blogFound.smallimage1purchased || blogFound.smallimage2purchased || blogFound.smallimage3purchased)
         smallpurchase2 = (blogFound.smallimage4purchased || blogFound.smallimage5purchased)
         largepurchase = (blogFound.largeimage1purchased || blogFound.largeimage2purchased || blogFound.largeimage3purchased)
         miscpurchase = (blogFound.musicpurchased || blogFound.adbannerpurchased)
         purchases = (smallpurchase1 || smallpurchase2 || largepurchase || miscpurchase)
         return purchases
      end
      
      def adsWaitingPurchase(blogFound)
         smallimages1 = (blogFound.smallimage1 != "" || blogFound.smallimage2 != "" || blogFound.smallimage3 != "")
         smallimages2 = (blogFound.smallimage4 != "" || blogFound.smallimage5 != "")
         largeimages = (blogFound.largeimage1 != "" || blogFound.largeimage2 != "" || blogFound.largeimage3 != "")
         misc = (blogFound.adbanner != "" || blogFound.ogg != "" || blogFound.mp3 != "")
         waiting = (smallimages1 || smallimages2 || largeimages || misc)
         return waiting
      end
      
      def buylargeimage(blogFound)
         image1Purchased = (!blogFound.largeimage1purchased && blogFound.largeimage1 != "")
         image2Purchased = (!blogFound.largeimage2purchased && blogFound.largeimage2 != "")
         image3Purchased = (!blogFound.largeimage3purchased && blogFound.largeimage3 != "")
         cost = 0
         
         if(!image1Purchased)
            blogFound.largeimage1purchased = true
            cost += largeimage.amount
         end
         
         if(!image2Purchased)
            blogFound.largeimage2purchased = true
            cost += largeimage.amount
         end
         
         if(!image3Purchased)
            blogFound.largeimage3purchased = true
            cost += largeimage.amount
         end
         return cost
      end
      
      def buysmallimage(blogFound)
         image1Purchased = (!blogFound.smallimage1purchased && blogFound.smallimage1 != "")
         image2Purchased = (!blogFound.smallimage2purchased && blogFound.smallimage2 != "")
         image3Purchased = (!blogFound.smallimage3purchased && blogFound.smallimage3 != "")
         image4Purchased = (!blogFound.smallimage4purchased && blogFound.smallimage4 != "")
         image5Purchased = (!blogFound.smallimage5purchased && blogFound.smallimage5 != "")
         cost = 0
         
         if(!image1Purchased)
            blogFound.smallimage1purchased = true
            cost += smallimage.amount
         end
         
         if(!image2Purchased)
            blogFound.smallimage2purchased = true
            cost += smallimage.amount
         end
         
         if(!image3Purchased)
            blogFound.smallimage3purchased = true
            cost += smallimage.amount
         end
         
         if(!image4Purchased)
            blogFound.smallimage4purchased = true
            cost += smallimage.amount
         end
         
         if(!image5Purchased)
            blogFound.smallimage5purchased = true
            cost += smallimage.amount
         end
         return cost
      end
      
      def buymisc(blogFound)
         cost = 0
         if(blogFound.adbanner != "" && !blogFound.adbannerpurchased)
            blogFound.adbannerpurchased = true
            cost += bannercost.amount
         end
         
         music = (blogFound.ogg != "" || blogFound.mp3 != "")
         if(music && !blogFound.musicpurchased)
            blogFound.musicpurchased = true
            cost += musiccost.amount
         end
         return cost
      end
      
      def callMaintenance(type)
         allMode = Maintenancemode.find_by_id(1)
         userMode = Maintenancemode.find_by_id(6)
         if(allMode.maintenance_on || userMode.maintenance_on)
            staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilge == "Betawriter"))
            if(staff)
               if(type == "index")
                  indexpage
               elsif(type == "show")
                  showpage
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
            if(type == "index")
               indexpage
            elsif(type == "show")
               showpage
            elsif(type == "new" || type == "create")
               createCommons(type)
            else
               editCommons(type)
            end
         end
      end

      def createCommons(type)
         logged_in = current_user
         userFound = User.find_by_vname(getBlogParams("User"))
         validCreator = (logged_in && userFound && logged_in.id == userFound.id)
         if(validCreator && logged_in.gameinfo.startgame)
            newBlog = logged_in.blogs.new
            if(type == "create")
               newBlog = logged_in.blogs.new(getBlogParams("Blog"))
               newBlog.created_on = currentTime
            end
            
            #Determines the type of bookgroup the user belongs to
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups

            #Allows us to choose the type of blog
            blogtypes = Blogtype.order("created_on desc")
            @blogtypes = blogtypes

            #Allows us to select the user who can view the blog
            gviewers = Gviewer.order("created_on desc")
            @gviewers = gviewers
            @blog = newBlog
            @user = userFound
            
            if(adsWaitingPurchase(blogFound))
               price = 0
               price += buysmallimage(blogFound)
               price += buylargeimage(blogFound)
               price += buymisc(blogFound)
               if(logged_in.pouch.amount - price >= 0)
                  if(@blog.save)
                     url = "http://www.duelingpets.net/blogs/review"
                     ContentMailer.content_review(@blog, "Adblog", url).deliver_later(wait: 5.minutes)
                     flash[:success] = "#{@blog.user.vname} Adblog #{@blog.title} was successfully created."
                     redirect_to user_blog_path(@user, @blog)
                  else
                     render "new"
                  end
               else
                  flash[:error] = "#{newBlog.user.vname} can't afford the ads price!"
                  redirect_to root_path
               end
            else
               if(@blog.save)
                  url = "http://www.duelingpets.net/blogs/review"
                  ContentMailer.content_review(@blog, "Blog", url).deliver_later(wait: 5.minutes)
                  flash[:success] = "#{@blog.user.vname} blog #{@blog.title} was successfully created."
                  redirect_to user_blog_path(@user, @blog)
               else
                  render "new"
               end
            end
         else
            if(!validCreator)
               flash[:error] = "Only logged in users can create content!"
            else
               flash[:error] = "{logged_in.vname} has not activated their game yet!"
            end
            redirect_to root_path
         end
      end

      def editCommons(type)
         logged_in = current_user
         blogFound = Blog.find_by_id(getBlogParams("Id"))
         owner = (logged_in && blogFound && logged_in.id == blogFound.user_id)
         staff = (logged_in && (logged_in.pouch.privilege == "Admin" || logged_in.pouch.privilege == "Betawriter"))
         if(blogFound && (staff || owner))
            blogFound.updated_on = currentTime
            allGroups = Bookgroup.order("created_on desc")
            allowedGroups = allGroups.select{|bookgroup| bookgroup.id <= getWritingGroup(logged_in, "Id")}
            @group = allowedGroups
            
            #Allows us to choose the type of blog
            blogtypes = Blogtype.order("created_on desc")
            @blogtypes = blogtypes

            #Allows us to select the user who can view the blog
            gviewers = Gviewer.order("created_on desc")
            @gviewers = gviewers

            blogFound.reviewed = false
            @blog = blogFound
            @user = User.find_by_vname(blogFound.user.vname)
            if(type == "update")
               if(adsPurchased(blogFound) || adsWaitingPurchase(blogFound))
                  price = 0
                  price += buysmallimage(blogFound)
                  price += buylargeimage(blogFound)
                  price += buymisc(blogFound)
                  if(price == 0 || @blog.user.pouch.amount - price >= 0)
                     if(@blog.update_attributes(getBlogParams("Blog")))
                        url = "http://www.duelingpets.net/blogs/review"
                        ContentMailer.content_review(@blog, "Adblog", url).deliver_later(wait: 5.minutes)
                        flash[:success] = "Adblog #{@blog.title} was successfully updated."
                        redirect_to user_blog_path(@blog.user, @blog)
                     else
                        render "edit"
                     end
                  else
                     flash[:error] = "You have insufficient points to pay for all these ads!"
                     redirect_to root_path
                  end
               else
                  if(@blog.update_attributes(getBlogParams("Blog")))
                     url = "http://www.duelingpets.net/blogs/review"
                     ContentMailer.content_review(@blog, "Blog", url).deliver_later(wait: 5.minutes)
                     flash[:success] = "Blog #{@blog.title} was successfully updated."
                     redirect_to user_blog_path(@blog.user, @blog)
                  else
                     render "edit"
                  end
               end
            elsif(type == "destroy")
               cleanup = Fieldcost.find_by_name("Blogcleanup")
               if(staff || (blogFound.user.gameinfo.startgame && blogFound.user.pouch.amount - cleanup.amount >= 0))
                  if(!staff)
                     #Removes the content and decrements the owner's pouch
                     blogFound.user.pouch.amount -= cleanup.amount
                     @pouch = blogFound.user.pouch
                     @pouch.save
                     economyTransaction("Sink", cleanup.amount, blogFound.user.id, "Points", "Blog")
                  end
                  flash[:success] = "#{@blog.title} was successfully removed."
                  @blog.destroy
                  if(staff)
                     redirect_to blogs_list_path
                  else
                     redirect_to user_blogs_path(blogFound.user)
                  end
               else
                  if(!blogFound.user.gameinfo.startgame)
                     flash[:error] = "The game hasn't started yet you silly squirrel. LOL!"
                  else
                     flash[:error] = "#{@blog.user.vname}'s has insufficient points to remove the blog!"
                  end
                  redirect_to root_path
               end
            end
         else
            if(!blogFound)
               flash[:error] = "Blog doesn't exist!"
            else
               flash[:error] = "User doesn't have permission to edit this blog!"
            end
            redirect_to root_path
         end
      end

      def mode(type)
         if(timeExpired)
            logoutUser("Single")
            redirect_to root_path
         else
            logoutUser("Multi")
            #removeTransactions
            if(type == "index")
               #Guest accessible
               callMaintenance(type)
            elsif(type == "new" || type == "create" || type == "edit" || type == "update" || type == "destroy")
               #Login only
               callMaintenance(type)
            elsif(type == "show")
               #Guest accessible
               callMaintenance(type)
            elsif(type == "list" || type == "review" || type == "approve" || type == "deny")
               #Staff only
               staff = (current_user && (current_user.pouch.privilege == "Admin" || current_user.pouch.privilege == "Betawriter"))
               if(staff && type == "review")
                  allBlogs = Blog.order("reviewed_on desc, created_on desc")
                  blogsToReview = allBlogs.select{|blog| !blog.reviewed}
                  @blogs = Kaminari.paginate_array(blogsToReview).page(getBlogParams("Page")).per(8)
               elsif(staff && type == "list") #Might change this slightly but looks better than earlier versions
                  allBlogs = Blog.order("reviewed_on desc, created_on desc")
                  @blogs = allBlogs.page(getBlogParams("Page")).per(8)
               else
                  blogFound = Blog.find_by_id(getBlogParams("BlogId"))
                  if(staff && blogFound && type == "approve")
                     if(adsPurchased(blogFound) || adsWaitingPurchase(blogFound))
                        price = 0
                        price += buysmallimage(blogFound)
                        price += buylargeimage(blogFound)
                        price += buymisc(blogFound)
                        if(price == 0)
                           blogFound.reviewed = true
                           blogFound.reviewed_on = currentTime
                           @blog = blogFound
                           @blog.save
                           ContentMailer.content_approved(@blog, "Adblog", price).deliver_later(wait: 5.minutes)
                           flash[:success] = "#{blogFound.user.vname}'s adblog #{blogFound.title} was approved."
                           redirect_to blogs_review_path
                        elsif(blogFound.user.gameinfo.startgame && blogFound.user.pouch.amount - price >= 0)
                           blogFound.reviewed = true
                           blogFound.reviewed_on = currentTime
                           rate = Ratecost.find_by_name("Purchaserate")
                           tax = (price * rate.amount)
                           
                           #Decrement the players pouch by the ads price
                           blogFound.user.pouch.amount -= price
                           @pouch = blogFound.user.pouch
                           @pouch.save
                           
                           #Adds points to the centralbank
                           hoard = Dragonhoard.find_by_id(1)
                           hoard.profit += tax
                           @hoard = hoard
                           @hoard.save
                           
                           #Displays the results of the transaction
                           @blog = blogFound
                           @blog.save
                           economyTransaction("Sink", price - tax, blogFound.user.id, "Points", "Adblog")
                           economyTransaction("Tax", tax, blogFound.user.id, "Points", "Adblog")
                           ContentMailer.content_approved(@blog, "Adblog", price).deliver_later(wait: 5.minutes)
                           flash[:success] = "#{blogFound.user.vname}'s adblog #{blogFound.title} was approved."
                           redirect_to blogs_review_path
                        else
                           if(!blogFound.user.gameinfo.startgame)
                              flash[:error] = "#{blogFound.user.vname} has not activated their game yet!"
                           else
                              flash[:error] = "#{blogFound.user.vname} can't afford the ads price!"
                           end
                           redirect_to blogs_review_path
                        end
                     elsif(blogFound.points_earned)
                        blogFound.reviewed = true
                        blogFound.reviewed_on = currentTime
                        @blog = blogFound
                        @blog.save
                        ContentMailer.content_approved(@blog, "Blog", 0).deliver_later(wait: 5.minutes)
                        economyTransaction("Source", points, @blog.user.id, "Points", "Blog")
                        flash[:success] = "#{blogFound.user.vname}'s blog #{blogFound.title} was approved."
                        redirect_to blogs_review_path
                     elsif(blogFound.user.gameinfo.startgame)
                        blogFound.reviewed = true
                        blogFound.reviewed_on = currentTime
                        blogFound.points_earned = true
                        mascot = Fieldcost.find_by_name("Mascot")
                        blog = Fieldcost.find_by_name("Blog")
                        
                        #Add points to the users pouch
                        points = blog.amount
                        if(blogFound.admascot != "")
                           points = mascot.amount
                        end
                        blogFound.user.pouch += points
                        @pouch = blogFound.user.pouch
                        @pouch.save
                        
                        #Displays the results of the transaction
                        @blog = blogFound
                        @blog.save
                        ContentMailer.content_approved(@blog, "Blog", points).deliver_later(wait: 5.minutes)
                        economyTransaction("Source", points, @blog.user.id, "Points", "Blog")
                        flash[:success] = "#{blogFound.user.vname}'s blog #{blogFound.title} was approved."
                        redirect_to blogs_review_path
                     else
                        flash[:error] = "#{blogFound.user.vname} has not activated their game yet!"
                        redirect_to blogs_review_path
                     end
                  elsif(staff && blogFound && type == "deny")
                     @blog = blogFound
                     ContentMailer.content_denied(@blog, "Blog").deliver_later(wait: 5.minutes)
                     flash[:success] = "#{@blog.user.vname}'s blog #{@blog.title} was denied."
                     redirect_to blogs_review_path
                  else
                     if(!blogFound)
                        flash[:error] = "Blog does not exist!"
                     else
                        flash[:error] = "This page is restricted to Staff only!"
                     end
                     redirect_to root_path
                  end
               end
            end
         end
      end
end
