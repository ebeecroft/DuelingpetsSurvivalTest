class TagablesController < ApplicationController
   include TagablesHelper

   def index
      mode "index"
   end

   def addtag
      mode "addtag"
   end

   def removetag
      mode "removetag"
   end
end
