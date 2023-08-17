class ApplicationController < ActionController::Base
   protect_from_forgery
   include PermissionsHelper
   include ChronosHelper
   include VisitorretrievalHelper
   include WordsHelper
end
