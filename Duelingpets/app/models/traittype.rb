class Traittype < ApplicationRecord
   has_many :traitmaps, :foreign_key => "traittype_id", :dependent => :destroy
end
