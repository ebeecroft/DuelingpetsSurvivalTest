class Elementmap < ApplicationRecord
   #Elementmaps related
   belongs_to :elementchart, optional: true
   belongs_to :element, optional: true
   belongs_to :damageoffset, optional: true
end
