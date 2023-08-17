class Entitytype < ApplicationRecord
   has_many :traitmaps, :foreign_key => "entitytype_id", :dependent => :destroy
end
